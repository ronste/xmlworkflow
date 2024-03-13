# run all conversions (default)
all: _default pdf

[private]
@help:
  echo "Usage: [ processDocx | just ] [ theme=<theme> | debug=true | validate=true | develop=true ] [ docx=<filename> ] [ <recipe> ]"
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
  echo ""
  just --list

set dotenv-load := true

[private]
alias Pandoc := pandoc
[private]
alias pandoc-xml := pandoc
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
docx := '$(basename "$(find . -type f -name "*.docx" | head -n 1)")'
debug := 'false'
validate := 'false'
develop := 'false'

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
  cp {{ if debug == "true" { "--verbose" } else { "" } }} "$WORK_PATH/{{docx}}_Pandoc.xml" "$WORK_PATH/buffer.tmp"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $RES_PATH/logo/* $WORK_PATH/media

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
    net.sf.saxon.Transform -s:"$WORK_PATH/buffer.tmp" \
    -xsl:"$UTILS_PATH/pandoc_post_process.xsl" \
    -o:"$WORK_PATH/{{docx}}_SaxonHE.xml"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} "$WORK_PATH/{{docx}}_SaxonHE.xml" "$WORK_PATH/buffer.tmp"
  # validate xml
  if [ "{{ validate }}" = "true" ]; then \
    echo -e "{{hcs}}Validating XML with xmllint ...{{nc}}"; \
    xmllint "$WORK_PATH/{{docx}}_SaxonHE.xml" --noout --dtdvalid; \
      if [ $? -eq 0 ]; then \
        echo -e "{{hcs}}Validation successfull{{nc}}"; \
      else \
        echo -e "{{wcs}}XML-document is not valid!{{nc}}"; \
      fi \
  fi

# Convert docx to XML using Pandoc + Saxon HE 12
xml: pandoc xml-

# Convert XML to HTML using Saxon HE 12
[no-cd, private]
html-: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/jats_html.css $WORK_PATH/media/jats_html.css
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $RES_PATH/logo/* $WORK_PATH/media
  echo -e "{{hcs}}Converting XML to HTML with Saxon HE 12 ...{{nc}}"
  # run citation conversion
  java -cp "{{javaClassPath}}" \
    net.sf.saxon.Transform -s:"$WORK_PATH/buffer.tmp" \
    -xsl:"$XSL_PATH/jats-APAcit.xsl" \
    -o:"$WORK_PATH/{{docx}}_SaxonHE_cit.xml"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} "$WORK_PATH/{{docx}}_SaxonHE_cit.xml" "$WORK_PATH/buffer.tmp"
  # run html conversion
  java -cp "{{javaClassPath}}" \
    net.sf.saxon.Transform -s:"$WORK_PATH/buffer.tmp" \
    -xsl:"$XSL_PATH/jats-html.xsl" \
    -o:"$WORK_PATH/{{docx}}_SaxonHE.html"
  # add development styles
  if [ "{{ develop }}" = "true" ]; then \
    echo -e "{{wcs}}Adding development styles ...{{nc}}"; \
    sed "{{develop_html_fragment}}" -i "$WORK_PATH/{{docx}}_SaxonHE.html"; \
    cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/pagedjs.css $WORK_PATH/media/pagedjs.css; \
    cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/develop.css $WORK_PATH/media/develop.css; \
    echo -e "TODO: start development server"; \
  fi
  cp "$WORK_PATH/{{docx}}_SaxonHE.html" "$WORK_PATH/buffer.html"
  # validate html
  if [ "{{ validate }}" = "true" ]; then \
    echo -e "{{hcs}}Validating XML with xmllint ...{{nc}}"; \
    xmllint "$WORK_PATH/{{docx}}_SaxonHE.html" --noout --valid --html; \
      if [ $? -eq 0 ]; then \
        echo -e "{{hcs}}Validation successfull{{nc}}"; \
      else \
        echo -e "{{wcs}}XML-document is not valid!{{nc}}"; \
      fi \
  fi

# Convert XML to HTML using Saxon HE 12
html: _default xml html-

# Generate PDF using Pandoc, Pagedjs and Weasyprint
[private]
pdf-: _default pandoc-pdf- pagedjs- weasyprint-

# Generate PDF using Pandoc, Pagedjs and Weasyprint
pdf: _default html pandoc-pdf- pagedjs- weasyprint-

# Generate PDF using Pandoc
[no-cd, private]
pandoc-pdf-: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{hcs}}Converting HTML to PDF with Pandoc ...{{nc}}"
  pandoc "$WORK_PATH/buffer.html" -s \
      -f html \
      --pdf-engine=pdflatex \
      --template="$DEFAULT_TEMPLATE_PATH/pdf_template_pandoc.tex" \
      --metadata-file="$METADATA_PATH/metadata.yaml" \
      -t pdf \
      -o "$WORK_PATH/{{docx}}_Pandoc.pdf"

# Generate PDF using Pandoc
pandoc-pdf: _default html pandoc-pdf-

# Generate PDF using Pagedjs
[no-cd, private]
pagedjs-:
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
    -i "$WORK_PATH/buffer.html" \
    -o "$WORK_PATH/{{docx}}_pagedjs.pdf"

# Generate PDF using Pagedjs
pagedjs: _default html pagedjs-

# Generate PDF using Weasyprint
[private]
weasyprint-: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  # https://doc.courtbouillon.org/weasyprint/stable/first_steps.html
  # https://weasyprint.org/
  # http://test.weasyprint.org/suite-css-page-3/chapter4/section1/
  echo -e "{{hcs}}Processing MathML with Mathjax ... {{nc}}"
  # https://github.com/mathjax/MathJax-demos-node
  # node -r esm needs to be executed in the lib folder; just escape seqeunce does not work 
  docx_file="{{docx}}" && cd $LIB_PATH && node -r esm "mml2chtml-page" "$WORK_PATH/buffer.html" > "$WORK_PATH/${docx_file}_mathjax.html" && cd $WORK_PATH
  echo -e "{{hcs}}Converting to PDF with WeasyPrint ...{{nc}}"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/weasyprint.css $WORK_PATH/media/weasyprint.css
  weasyprint {{ if debug == "true" { "-d -v" } else { "" } }} \
    -m print -p \
    -s "$WORK_PATH/media/weasyprint.css" \
    {{ if develop == "true" { "-s $CSS_PATH/develop.css" } else { "" } }} \
    -p "$WORK_PATH/{{docx}}_mathjax.html" "$WORK_PATH/{{docx}}_weasyprint.pdf"

# Generate PDF using Weasyprint
weasyprint: _default html weasyprint-

_cleanup:
  rm "$WORK_PATH/buffer.tmp"