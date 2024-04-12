#! /bin/bash
set -euo pipefail
cd /root/xmlworkflow/work
processDocx
processDocx validate=true html-
processDocx debug=true validate=true develop=true weasyprint-
processDocx pandoc-pdf-xml-
processDocx theme=berlinup validate=true reset-example html
processDocx -f /root/xmlworkflow/themes/berlinup/justfile debug=true custom-example
processDocx docxtojats
processDocx xml-file='/root/xmlworkflow/work/buffer.xml' xml-validate
processDocx reset-example
processDocx
processDocx xml-file=buffer.xml html-