# XML Workflow Image

- Version: 1.0
- Developed by: Ronald Steffen

---

This repo contains a container image assembling different open source tools and a range of open source template files into a toolchain that provides a docx -> xml -> html -> pdf workflow for single-source Jats-XML publishing.

***NOTE: This repo is under development.***
This repo is intended as a proof-of-concept tool. In particular the templates require significant revision and improvement. I don't play around with Latex. So don't count on any developments of the pandoc-pdf Latex template. Documantation is incomplete.

The tools included are:

- Pandoc 3.1.11.1
- luarocks 3.9.2
- Saxon HE 12 4J
- mathjax-full 3.2.2
- pagedjs-cli 0.4.3 (with puppeteer 22.4.1)
- WeasyPrint version 57.2
- just-install 2.0.1 (for task execution)

Template files and other sources (e.g. css) are dereived from:

- Pandoc default templates
- Preview of NISO JATS Publishing 1.0 XML
- NLM/NCBI  Journal Publishing 3.0 Preview HTML
- Journal Publishing 3.0 APA-like Citation

## Usage

To run a full docx to pdf conversion a specifically prepared MS Word docx document needs to be placed inside the working directory. The docx document is requiered to use specific formating templates as explained below.

1) Build the conainter image according to your platform (e.g. Docker, Podman, ...) with the image name `xmlworkflow:latest`
2) Run the image in a conatiner with `docker-compose up --detach`
3) Start the docx conversion with the following command:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx"`

This will craete a range of intermediate and final files in the working directory which will be named according to the conversion step (tool) they are corresponding to. E.g. `<docx-filename>_SaxonHE.html` or `<docx-filename>_weasyprint.pdf`.

Running the processDocx command without any parameters will start the full chain of conversion from docx -> xml -> html -> pdf, including all versions of PDFs (created with Pandoc, PagedJs and Weasyprint).

However, each of these conversion steps can be selected individually. To only run a conversion from docx to HTML use:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx html"`

If the Jats XML file requried to create the HTML output is already present in the working directory you can run the HTML conversion without its prior conversion steps by using:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx html-"`

To get an overview of all options run:

`docker exec xmlworkflow /bin/bash -c "cd /root/xmlworkflow/work && processDocx help`

which will output:

```text
Usage: [ processDocx | just ] [ theme=<theme> | debug=true | validate=true | develop=true ] [ docx=<filename> ] [ <recipe> ]

To run a recipe without its dependencies add a "-" to the recipes name, e.g. "weasyprint-"
If no docx file is provided the first docx file in the working dirctory will be taken.
If no recipe is provided the full conversion chain is run and all available versions of PDFs will be created.

Options:
    theme=<theme>: Selects a set of templates (i.e. a sub folder of the themes folder) to be used for conversion.
    debug=true: Enables the debug options of the different tools.
    validate=true: Runs an XML validation with xmllint.
    develop=true: Adds specific css rules to the conversion of HTML and PDF files to provide features for debugging and development of Print CSS conversion steps.
    docx=<filename>: Specifies the path and name of the docx file to be converted.

Available recipes:
    all        # run all conversions (default)
    html       # Convert XML to HTML using Saxon HE 12
    pagedjs    # Generate PDF using Pagedjs
    pandoc     # Convert docx to XML with Pandoc
    pandoc-pdf # Generate PDF using Pandoc
    pdf        # Generate PDF using Pandoc, Pagedjs and Weasyprint
    weasyprint # Generate PDF using Weasyprint
    xml        # Convert docx to XML using Pandoc + Saxon HE 12
```

The xmlworkflow container supports the definition of custom themes, i.e. different sets of templates, css and media files.
To create a custom theme create a copy of the folder `themes/default` within the themes folder.
You can then use the theme by providing the option `theme=<folder name>` and customize the templates inside this folder.

## How it works

Todo: Write more documentation

## Disclaimer

This repo is developed in the context of the services offered by Berlin Universities Publishing Journals (operated by the University Library FU Berlin) and licensed under GNU GENERAL PUBLIC LICENSE Version 3.
