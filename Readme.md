# XML Workflow Image

- Version: 1.3 (10.4.2024)
- Developed by: Ronald Steffen

---

This repo contains a container image assembling different open source tools and a range of open source template files into a flexible framework that allows to define conversion toolchains. Currently it provides `docx -> (Jats) XML -> html -> pdf` and `docx -> (Jats) XML -> pdf` toolchains for single-source Jats-XML publishing.

***NOTE: This repo is under development.***
This repo is intended as a proof-of-concept tool. In particular the templates require significant revision and improvement. I don't play around with Latex. So don't count on any developments of the pandoc-pdf Latex template. Documantation is incomplete.

The tools included are:

- [Pandoc](https://pandoc.org/) 3.1.12.2
- [luarocks](https://luarocks.org/) 3.9.2
- [Saxon HE 12 4J](https://www.saxonica.com/documentation12/documentation.xml)
- [mathjax-full](https://www.mathjax.org/) 3.2.2
- [Pagedjs](https://pagedjs.org/) and [pagedjs-cli](https://github.com/pubpub/pagedjs-cli) 0.4.3 (with puppeteer 22.4.1)
- [WeasyPrint](https://weasyprint.org/) version 57.2
- [docxToJats](https://github.com/Vitaliy-1/docxToJats)
- [just](https://github.com/casey/just) 2.0.1 (for task execution)

Template files and other sources (e.g. css) are dereived from:

- Pandoc default templates
- Preview of [NISO JATS Publishing 1.0](https://jats.nlm.nih.gov/publishing/tag-library/1.0/) XML
- [NLM/NCBI  Journal Publishing 3.0](https://dtd.nlm.nih.gov/publishing/3.0/) Preview HTML
- Journal Publishing 3.0 APA-like Citation

## Usage

To run a full docx to pdf conversion a specifically prepared MS Word docx document needs to be placed inside the working directory. The docx document is requiered to use specific formating templates as explained in the [documentation](Documentation.md).
Please note that the default conversion chain (which hnadles metadata from the docx document) is optimized for docx -> Jats XML conversion via Pandoc (for customized conversion chains see [below](#how-to-run-a-custom-conversion-chain)).

1) Build the conainter image according to your platform (e.g. Docker, Podman, ...) with the image name `xmlworkflow:latest`
2) Run the image in a conatiner with `docker-compose up --detach`
3) Start the docx conversion with the following command:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx"`

This will create a range of intermediate and final files in the working directory which will be named according to the conversion step (tool) they are corresponding to. E.g. `<docx-filename>_SaxonHE.html` or `<docx-filename>_weasyprint.pdf`.

To get an overview of all options run:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx help`

which will output:

```text
Usage: [ processDocx | just ] [ theme=<theme> | debug=true | validate=true | develop=true  | pagedjs-polyfill=true ] [ docx=<filename> ] [ <recipe> ]

To run a recipe without its dependencies add a "-" to the recipes name, e.g. "weasyprint-"
If no docx file is provided the first docx file in the working dirctory will be taken.
If no recipe is provided the full conversion chain is run and all available versions of PDFs will be created.

Options:
    theme=<theme>: Selects a set of templates (i.e. a sub folder of the themes folder) to be used for conversion.
    debug=true: Enables the debug options of the different tools.
    validate=true: Runs an XML validation with xmllint.
    develop=true: Adds specific css rules to the conversion of HTML and PDF files to provide features for debugging and development of Print CSS conversion steps.
    docx=<filename>: Specifies the path and name of the docx file to be converted.
    pagedjs-polyfill=true: Adds the Pagedjs polyfill to the final HTML output for debugging purpose.

Available recipes:
    all                           # run all conversions (default)
    cleanup-work                  # Clean up the working directory removing all files in work and in work/media
    docxtojats                    # Generate Jats XML using the docxtojats converter
    html                          # Convert XML to HTML using Saxon HE 12
    mathjax                       # Generate PDF using mathjax
    pagedjs                       # Generate PDF using Pagedjs
    pandoc                        # Convert docx to XML with Pandoc
    pandoc-pdf-html               # Generate PDF from HTML using Pandoc
    pandoc-pdf-xml                # Generate PDF from XML using Pandoc
    pdf                           # Generate PDF using Pandoc, Pagedjs and Weasyprint
    reset-example                 # Clean up the working directory and reset example file
    runtests                      # Run different test scripts
    weasyprint                    # Generate PDF using Weasyprint
    xml                           # Convert docx to XML using Pandoc + Saxon HE 12
    xml-validate filename="false" # Validate XML file against DTD provided by DOCTYPE tag. Usage: "processDocx xml-validate <filename>"
```

More information on individual conversion steps may be available by running:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx help <recipe-name>`

### The default (docx-based) conversion chain

Running the processDocx command without any parameters will start the full chain of conversion from docx -> xml -> html -> pdf, including all versions of PDFs (created with Pandoc, PagedJs and Weasyprint).

However, each of these conversion steps can be selected individually. To only run a conversion from docx to HTML use:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx html"`

If, due to a previous run, the Jats XML buffer file requried to create the HTML output is already present in the working directory you can run the HTML conversion without its prior conversion steps by using:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx html-"`

Note that it is also possible to specify specific conversion chains directly by passing multiple recipe names to the`processDocx` command:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx pagedjs weasyprint"`

### Using custom themes

The xmlworkflow container supports the definition of custom themes, i.e. different sets of templates, css and media files.
To create a custom theme create a copy of the folder `themes/default` within the themes folder.
You can then use the theme by providing the option `theme=<folder name>` and customize the templates inside this folder.

A theme may also contain its own justfile to define custom conversion steps. Not surprisingly, it should (but is not required to) import the main justfile. To run a conversion from this theme-specific justfile you directly specifiy the path to your custom justfile, e.g.:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx -f /root/xmlworkflow/themes/default/justfile help"`

If you run the above command you find an additional recipes `custom-help` and `custom-example` were added.

You could e.g. define a step doing a Markdown to XML conversion with Pandoc to build your own Markdown -> Jats XML -> ... conversion chain for one particular theme.

### How to run a custom conversion chain

To run a custom conversion chain, e.g. not using the default Pandoc docx to Jats XML conversion, you can specifiy your conversion steps directly on the command line. In the following example docx to Jats XML conversion is facilitated by the [docxToJats converter](https://github.com/Vitaliy-1/docxToJats) and the resulting Jats XML file is subsequently passed through the default Jats XML -> HTML -> Weasyprint conversion steps.
The minus sign at the end of the subsequent recipe names is important in this use case, since it indicates that only the recipe without its default dependecies (which would be Pandoc) should be run.

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx docxtojats html- weasyprint-"`

### How to run conversion chains not based on docx documents

If you run the recipes `xml-`, `html-`, `pagedjs-` or `weasyprint-` you may pass a filename as additional parameter. This allows to run these conversion steps on an existing xml or html file from a different source than the default docx file. The following command e.g. performs an `xml -> html -> pdf` conversion without requiring a docx file:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx html- Dummy_Article_Template.docx_SaxonHE.xml weasyprint-"`

Please don't forget to put all dependent files into the media folder.`

## How to develop, debug and test Print CSS stylesheets

To help with developing and debugging Print CSS stylesheets the develop=true option is available. This will add special css to the conversion process that may help you to identify possible issues.

The applied CSS, e.g., will color backgrounds for the html and body tags and add borders to the Print CSS page margin boxes. You can see these in the Pdf files and with the Pagedjs polyfill option.

You can also view the HTML file in print mode in Firefox. To do so open the developer tools and go to the Inspector tab. In the upper right corner of the styles section enable the icon "Toggle print media simulation for the page".
This will show the HTML file with all @media print styles enabled and you can inspect any issues interactively without added development CSS.

For specifically debugging Pagedjs issues you can add the Pagedjs polyfill to you HTML file by using the option `pagedjs-polyfill=true`.
However, please not that the Pagedjs polyfill and pagedjs-cli (as currently used for the conversion) might behave differently under some circumstances (see below).

An empty HTML template that loads the development CSS and the Pagedjs polyfill is provided with the file `themes\default\templates\html_template_printcss.html`. You can inspect this file with your browser to learn about the basic Print CSS page layout. Note however, that Pagedjs and Weasyprint handle these layout elements differently!

To run a set of different tests use:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx runtests"

## Next steps

- Continuous imporovements of template files
- Implementation of a web app to provide a REST-API to handle [Dar packages](https://github.com/substance/dar)
- considering pagedjs polyfill vs pagedjs-cli
- revise handling of resource files between themes

## Known issues

- As of Pandoc version 3.1.12.2 the Pandoc HTML reader complains about unclosed HTML tags (used to work with Pandoc 3.1.11). Therefore the HTML -> PDF conversion with Pandoc is currently broken.
- Rendering of large tables works well with Pagedjs polyfill but has issues with pagedjs-cli: page width is not considered.

## Version history

1.1 New recipes added
1.2 Added feature to define theme-specific custom conversion steps
1.3 Added docxtojats converter, added runtests and xml-validate recipes

## Disclaimer

This repo is developed in the context of the services offered by Berlin Universities Publishing Journals (operated by the University Library FU Berlin) and licensed under GNU GENERAL PUBLIC LICENSE Version 3.
