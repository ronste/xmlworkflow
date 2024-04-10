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
processDocx xml-validate /root/xmlworkflow/work/buffer.xml