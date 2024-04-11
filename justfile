# run all conversions (default)
all: _default pdf

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

import 'justfiles/default-justfile'
import 'justfiles/help-justfile'
import 'justfiles/pandoc-justfile'
import 'justfiles/xml-justfile'
import 'justfiles/html-justfile'
import 'justfiles/pagedjs-justfile'
import 'justfiles/weasyprint-justfile'
import 'justfiles/docxtojats-justfile'
import 'justfiles/xmllint-justfile'

# Generate PDF using Pandoc, Pagedjs and Weasyprint
[private]
pdf-: _default (pandoc-pdf- pandoc_from) pagedjs- weasyprint-

# Generate PDF using Pandoc, Pagedjs and Weasyprint
pdf: _default html (pandoc-pdf- pandoc_from) pagedjs- weasyprint-

[no-cd]
@_cleanup-tmp:
  -rm $WORK_PATH/buffer.xml $WORK_PATH/buffer.html 2> /dev/null

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