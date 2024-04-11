# run all conversions (default)
all: _default pdf

[private]
help topic="help":
  #!/usr/bin/env bash
  set -euo pipefail
  case {{topic}} in
    'help')
      just default-help
      ;;

    'pandoc')
      just _pandoc-help
      ;;

    'xml')
      just _xml-help
      ;;

    'html')
      just _html-help
      ;;

    'pagedjs')
      just _pagedjs-help
      ;;

    'weasyprint')
      just _weasyprint-help
      ;;

    *)
      echo 'No help for this recipe available.'
      ;;
  esac


[private]
@default-help:
  echo "Usage: [ processDocx | just ] [ theme=<theme> | debug=true | validate=true | develop=true  | pagedjs-polyfill=true ] [ docx=<filename> ] [ <recipe> ]"
  echo ""
  echo 'To run a recipe without its dependencies add a "-" to the recipes name, e.g. "weasyprint-"'
  echo "If no docx file is provided the first docx file in the working dirctory will be taken."
  echo "If no recipe is provided the full conversion chain is run and all available versions of PDFs will be created." 
  echo ""
  echo "Options:"
  echo "    theme=<theme>: Selects a set of templates (i.e. a sub folder of the themes folder) to be used for conversion."
  echo "    debug=true: Enables the debug options of the different tools."
  echo "    validate=true: Runs an XML validation with xmllint."
  echo "    develop=true: Adds specific css rules to the conversion of HTML and PDF files to provide features for debugging and development of Print CSS conversion steps."
  echo "    docx=<filename>: Specifies the path and name of the docx file to be converted."
  echo "    pagedjs-polyfill=true: Adds the Pagedjs polyfill to the final HTML output for debugging purpose."
  echo ""
  just --list

set dotenv-load := true

[private]
alias Pandoc := pandoc
[private]
alias pandoc-xml := pandoc
[private]
alias pandoc-pdf := pandoc-pdf-html
[private]
alias XML := xml
[private]
alias HTML := html
[private]
alias PDF := pdf
[private]
alias Pagedjs := pagedjs
[private]
alias WeasyPrint := weasyprint
[private]
alias Weasyprint := weasyprint
[private]
alias weasy := weasyprint

# command line parameters
theme := 'default'
docx := '$(basename "$(find $WORK_PATH -type f -name "*.docx" | head -n 1)")'
debug := 'false'
validate := 'false'
develop := 'false'
pandoc_from := 'XML'
pagedjs-polyfill := 'false'

# path variables
develop_html_fragment := '$(echo "/<head/ r "$XSL_PATH/html_fragment_develop.html"")'
javaClassPath := "$LIB_PATH/SaxonHE12-4J/saxon-he-12.4.jar:$LIB_PATH/SaxonHE12-4J/lib/xmlresolver-5.2.2.jar"

# color defnitions
hcs := '\033[0;32m' # heading color start
nc := '\033[0m'    # no color
wcs := '\033[0;31m' # warning color start

# run for all recipies
_default:
  #!/usr/bin/env bash
  set -euo pipefail
  # set all dynamic environment variables (others will be set via .env file)
  sed -i '/^export TEMPLATE_PATH=/d' ~/.bashrc
  sed -i '/^export XSL_PATH=/d' ~/.bashrc
  sed -i '/^export CSS_PATH=/d' ~/.bashrc
  sed -i '/^export RES_PATH=/d' ~/.bashrc
  echo 'export TEMPLATE_PATH="$THEME_PATH/{{theme}}/templates"' >> ~/.bashrc
  echo 'export XSL_PATH="$THEME_PATH/{{theme}}/xsl"'  >> ~/.bashrc
  echo 'export CSS_PATH="$THEME_PATH/{{theme}}/css"'  >> ~/.bashrc
  echo 'export RES_PATH="$THEME_PATH/{{theme}}/res"'  >> ~/.bashrc
  # Apply the changes
  source ~/.bashrc
  # print user info
  echo "Working directory is: $WORK_PATH"
  echo "Theme path is:        $THEME_PATH"
  echo "Utils path is:        $UTILS_PATH"
  echo "Input file is:        {{docx}}"

_pandoc-help:
  #!/bin/bash
  cat << EOF
  The Pandoc help is under construntion.
  EOF

# Convert docx to XML with Pandoc
[no-cd]
pandoc: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{hcs}}Converting docx to XML with Pandoc ...{{nc}}"
  pandoc {{ if debug == "true" { "--verbose" } else { "" } }} $WORK_PATH/{{docx}} -s \
    -f docx+styles+citations \
    --extract-media="." \
    --metadata-file="$METADATA_PATH/metadata.yaml" \
    --citeproc \
    --template "$UTILS_PATH/jats_template.tex" \
    -t "$UTILS_PATH/custom_jats_writer.lua" \
    -o "$WORK_PATH/{{docx}}_Pandoc.xml"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} "$WORK_PATH/{{docx}}_Pandoc.xml" "$WORK_PATH/buffer.xml"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $RES_PATH/logo/* $WORK_PATH/media

_xml-help:
  #!/bin/bash
  cat << EOF
  The XML help is under construntion.
  EOF

# debug with:
# java -p lib/SaxonHE12-4J/saxon-he-12.4.jar --list-modules
# java -verbose:class net.sf.saxon.Transform
# java classpath separator is ":" on Linux and ";" on Windows !!!
# Convert docx to XML using Pandoc + Saxon HE 12
[private]
xml-: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{hcs}}XSLT post processing with Saxon HE 12 ...{{nc}}"
  java -cp "{{javaClassPath}}" \
    net.sf.saxon.Transform -s:"$WORK_PATH/buffer.xml" \
    -xsl:"$UTILS_PATH/pandoc_post_process.xsl" \
    -o:"$WORK_PATH/{{docx}}_SaxonHE.xml"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} "$WORK_PATH/{{docx}}_SaxonHE.xml" "$WORK_PATH/buffer.xml"
  if [ "{{ validate }}" = "true" ]; then \
    just xml-validate "$WORK_PATH/{{docx}}_SaxonHE.xml"; \
  fi
# Convert docx to XML using Pandoc + Saxon HE 12
xml: pandoc xml-

_html-help:
  #!/bin/bash
  cat << EOF
  The HTML help is under construntion.
  EOF

# Convert XML to HTML using Saxon HE 12
[no-cd, private]
html- filename="buffer.xml": _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/jats_html.css $WORK_PATH/media/jats_html.css
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $RES_PATH/logo/* $WORK_PATH/media
  echo -e "{{hcs}}Converting XML to HTML with Saxon HE 12 ...{{nc}}"
  # run citation conversion
  java -cp "{{javaClassPath}}" \
    net.sf.saxon.Transform -s:"$WORK_PATH/{{filename}}" \
    -xsl:"$XSL_PATH/jats-APAcit.xsl" \
    -o:"$WORK_PATH/{{docx}}_SaxonHE_cit.xml"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} "$WORK_PATH/{{docx}}_SaxonHE_cit.xml" "$WORK_PATH/{{filename}}"
  # run html conversion
  java -cp "{{javaClassPath}}" \
    net.sf.saxon.Transform -s:"$WORK_PATH/{{filename}}" \
    -xsl:"$XSL_PATH/jats-html.xsl" \
    -o:"$WORK_PATH/{{docx}}_SaxonHE.html"
  # add development styles
  if [ "{{ develop }}" = "true" ]; then \
    echo -e "{{wcs}}Adding development styles ...{{nc}}"; \
    sed "{{develop_html_fragment}}" -i "$WORK_PATH/{{docx}}_SaxonHE.html"; \
    cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/develop.css $WORK_PATH/media/develop.css; \
    echo -e "TODO: start development server"; \
  fi
  # copy to buffer
  cp "$WORK_PATH/{{docx}}_SaxonHE.html" "$WORK_PATH/buffer.html"
  # add pagedjs polyfill to output file only
  if [ "{{ pagedjs-polyfill }}" = "true" ]; then \
    echo -e "{{wcs}}Adding pagedjs polyfill ...{{nc}}"; \
    sed -i '/<head>/a <script src="https://unpkg.com/pagedjs/dist/paged.polyfill.js"></script>' "$WORK_PATH/{{docx}}_SaxonHE.html"; \
    sed -i '/<head>/a <link rel="stylesheet" type="text/css" href="media/pagedjs.css">' "$WORK_PATH/{{docx}}_SaxonHE.html"; \
  fi
  # validate html
  set +e
  if [ "{{ validate }}" = "true" ]; then \
    echo -e "{{hcs}}Validating XML with html-validate ...{{nc}}"; \
    # xmllint "$WORK_PATH/{{docx}}_SaxonHE.html" --noout --valid --html; \
    # https://html-validate.org/usage/cli.html
    html-validate "$WORK_PATH/{{docx}}_SaxonHE.html"
    if [ $? -eq 0 ]; then \
      echo -e "{{hcs}}Validation successfull{{nc}}"; \
    else \
      echo -e "{{wcs}}HTML-document is not valid!{{nc}}"; \
    fi \
  fi
  set -e

# Convert XML to HTML using Saxon HE 12
html: _default xml html-

# Generate PDF using Pandoc, Pagedjs and Weasyprint
[private]
pdf-: _default (pandoc-pdf- pandoc_from) pagedjs- weasyprint-

# Generate PDF using Pandoc, Pagedjs and Weasyprint
pdf: _default html (pandoc-pdf- pandoc_from) pagedjs- weasyprint-

# Generate PDF using Pandoc
[no-cd, private]
pandoc-pdf- pandoc_from=pandoc_from: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{hcs}}Converting {{pandoc_from}} to PDF with Pandoc ...{{nc}}"
  pandoc "$WORK_PATH/buffer.{{pandoc_from}}" -s \
      -f {{ if pandoc_from == "html" { "html" } else { "jats" } }} \
      --pdf-engine=pdflatex \
      --template="$DEFAULT_TEMPLATE_PATH/pdf_template_pandoc.tex" \
      --metadata-file="$METADATA_PATH/metadata.yaml" \
      -t pdf \
      -o "$WORK_PATH/{{docx}}_Pandoc.pdf"

# Generate PDF from HTML using Pandoc
pandoc-pdf-html: _default html (pandoc-pdf- pandoc_from)

[private]
pandoc-pdf-html-: _default (pandoc-pdf- pandoc_from)

# Generate PDF from XML using Pandoc
pandoc-pdf-xml: _default xml (pandoc-pdf- "XML")

[private]
pandoc-pdf-xml-: _default (pandoc-pdf- "XML")

_pagedjs-help:
  #!/bin/bash
  cat << EOF
  The Pagedjs help is under construntion.
  EOF

# Generate PDF using Pagedjs
[no-cd, private]
pagedjs- filename="buffer.html":
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{hcs}}Converting to PDF with paged.js ...{{nc}}"
  # https://www.npmjs.com/package/pagedjs-cli
  # https://pagedjs.org/documentation/ 
  # https://gitlab.coko.foundation/pagedjs/pagedjs-cli
  # !!! pagedjs-cli fails with --debug option !!! a browser is required
  # !!! pagedjs-cli produces different results as compared to pagedjs polyfill !!!
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/pagedjs.css $WORK_PATH/media/pagedjs.css
  pagedjs-cli {{ if debug == "true" { "--warn" } else { "" } }} \
    --style "$WORK_PATH/media/pagedjs.css" \
    {{ if develop == "true" { "--style $DEFAULT_CSS_PATH/develop.css" } else { "" } }} \
    --browserArgs '--no-sandbox' \
    -i "$WORK_PATH/{{filename}}" \
    -o "$WORK_PATH/{{docx}}_pagedjs.pdf"

# Generate PDF using Pagedjs
pagedjs: _default html pagedjs-

_weasyprint-help:
  #!/bin/bash
  cat << EOF
  The Weasyprint help is under construntion.
  EOF

# Generate PDF using Weasyprint
[private]
weasyprint- filename="buffer.html": _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  # https://doc.courtbouillon.org/weasyprint/stable/first_steps.html
  # https://weasyprint.org/
  # http://test.weasyprint.org/suite-css-page-3/chapter4/section1/
  echo -e "{{hcs}}Processing MathML with Mathjax ... {{nc}}"
  # https://github.com/mathjax/MathJax-demos-node
  # node -r esm needs to be executed in the lib folder; just escape seqeunce does not work 
  docx_file="{{docx}}" && cd $LIB_PATH && node -r esm "mml2chtml-page" "$WORK_PATH/{{filename}}" > "$WORK_PATH/${docx_file}_mathjax.html" && cd $WORK_PATH
  cp "$WORK_PATH/{{docx}}_mathjax.html" "$WORK_PATH/{{filename}}"
  echo -e "{{hcs}}Converting to PDF with WeasyPrint ...{{nc}}"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/weasyprint.css $WORK_PATH/media/weasyprint.css
  weasyprint {{ if debug == "true" { "-d -v" } else { "" } }} \
    -m print -p \
    -s "$WORK_PATH/media/weasyprint.css" \
    {{ if develop == "true" { "-s $CSS_PATH/develop.css" } else { "" } }} \
    -p "$WORK_PATH/{{filename}}" "$WORK_PATH/{{docx}}_weasyprint.pdf"

# Generate PDF using Weasyprint
weasyprint: _default html weasyprint-

#Generate Jats XML using the docxtojats converter
docxtojats: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  php $LIB_PATH/docxToJats/docxtojats.php $WORK_PATH/{{docx}} $WORK_PATH/{{docx}}_docxtojats.xml
  cp $WORK_PATH/{{docx}}_docxtojats.xml $WORK_PATH/buffer.xml

[no-cd]
@_cleanup-tmp:
  -rm $WORK_PATH/buffer.xml $WORK_PATH/buffer.html 2> /dev/null

#Validate XML file against DTD provided by DOCTYPE tag. Usage: "processDocx xml-validate <filename>"
xml-validate filename="false":
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "{{ filename }}" != "false" ]; then \
    echo -e "{{hcs}}Validating XML with xmllint ...{{nc}}"; \
    xmllint {{filename}} --noout --dtdvalid; \
      if [ $? -eq 0 ]; then \
        echo -e "{{hcs}}Validation successfull{{nc}}"; \
      else \
        echo -e "{{wcs}}XML-document is not valid!{{nc}}"; \
      fi \
  else \
    echo -e "{{wcs}}Please provide a filename to validate!{{nc}}"; \
  fi

# Clean up the working directory removing all files in work and in work/media
[no-cd]
@cleanup-work:
  -rm $WORK_PATH/* 2> /dev/null
  -rm $WORK_PATH/media/* 2> /dev/null

# Clean up the working directory and reset example file
[no-cd]
@reset-example: cleanup-work
  cp $UTILS_PATH/Dummy_Article_Template.docx $WORK_PATH/Dummy_Article_Template.docx

#Run different test scripts
@runtests:
  $UTILS_PATH/run_tests.sh