#! /bin/bash
cd /root/xmlworkflow/work
processDocx reset-example pdf
processDocx validate=true html-
processDocx debug=true validate=true develop=true weasyprint-
processDocx pandoc-pdf-xml-
processDocx theme=berlinup validate=true reset-example html