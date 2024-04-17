# The XML workflow image

```text
Document version: 1.0 (2.4.2024)
```

> **_Todo_:** Write more documentation

This repo contains a container image assembling different open source tools for document conversion (listed in [Readme.md](Readme.md)) and a range of open source template files into a flexible framework that allows to define conversion toolchains. Although currently only docx documents are supported the framework itself is not in any way restricted to a specific document type.

## Basic concepts

The framework follows for a modular, tool independent, approach so simple conversion steps can be combined into different flexible conversion chains. It supports to define sets of document templates and other resource files (called themes) and allows to easily switch between them. In addition, themes may also define custom theme-specific conversion steps to set-up customized conversion chains (for any document type).

Many conversion tools focus on content conversion only. However, conversion to an annotated format like Jats XML also requires the handling of metadata. While a Word document may list the authors of an article in an arbitrary paragraph, to genarate a valid Jats XML document it is required to identify the metadata and transfer it to the appropriate jats XML tag.

In addition, for handling metadata within the publication process one also needs to consider the source of the metadata (e.g. author metadata or journal metadata) and the time within the publication process at which the metadata is available (e.g. author names at the time of submission and DOIs near the end of the publication process).

This framework provides means to handle these dependencies in an easy and configurable way.

## How it works

Each individual conversion step always requires an input file and produces an output file which can be further processed by the next conversion step in the chain. Starting with the inital docx input file each conversion step creates a buffer file that can be used by subsequent steps, and an identical file named according to the conversion stept following the naming convention `<docx file name>_<tool name>.<extension>`.

For example:
If the input file "Dummy_Article_Tempalte.docx" is processed with the recipe `pandoc-xml` to do a docx to Jats XML conversion with Pandoc it produces the identical files `buffer.xml` and `Dummy_Article_Tempalte.docx_Pandoc.xml`. While the file `buffer.xml` may be subsequently altered by other conversion steps, the file `Dummy_Article_Tempalte.docx_Pandoc.xml` will provide the final output of the conversion step `pandoc-xml`.

### Templates

Each conversion step requires templates to produce the desired output document. This even (and most importantly) holds true for the initial docx input document which is required to follow specific (customizable) rules.

#### The Word docx document template

To be able to identify annotated elements provided by the author inside the submitted docx document this framework uses the docx formating templates. Formating templates can be processed by Pandoc in the first conversion step for docx -> Jats XML conversion. This approach allows editorial teams to use their individual docx formating templates as annotaing elements for metadata provided by the authors.

To make this approach work it is required to assign each docx formating template that contains annotating information to specific Jats XML elements, which will be done in the Pandoc metadata.yaml file (see [Pandoc -> The metadata Yaml file](#the-metadata-yaml-file)).
For the conversion to work it is of uttermost importance that author stick to the defined formating templates. This should be verified by editors before initiating the conversion.

#### Templates used for conversion steps

### Themes

### The task runner (just)

### Custom conversion steps

## Available tools

### Pandoc

Pandoc is used with the `docx+styles+citations` extensions to allow processing of docx formating templates. The actual parsing of annotated docx paragraphs is performed in the custom Lua writer `utils/custom_jats_writer.lua`.

#### The metadata Yaml file

The file `themes/<selected theme>/templates/metadata.yaml` contains all default metadata and configuration options used by Pandoc.

For processing docx formating templates lists can be provided that map actual docx document template names used in the docx file to Jats XML annotation elements. In addition template names are defined which should be ingnored by Pandoc.
In the example below the docx document template named "Autor*in Name" is mapped to the Jats XML author information (which will be mapped to different Jats XML contributer tags), by assigning it to "authorNames":

```yaml
processStyles:
  # this maps jats tags to docx format templates
  title: Title
  abstract: Abstract
  keywords: Schlagwörter
  subject: Rubrik
  authorNames: "Autor*in Name"
  affiliations: "Autor*in Affiliation"
  corresp: "Corresponding Author"
ignoreStyles:
# this defines docx format templates to ignore
- Zeitschriften-Logo
- ISSN
- Zeitschriftentitel
- Ausgabe
- Autor*in E-Mail
- Datum Einreichung
- Datum Annahme
- Datum Publikation
- Lizenzinformationen
- Zitiervorschlag
- Bibliography
```

Note that, although the docx document template may contain formating templates with metadata not provided by the author. This type of journal metadata should usually not be read from the docx document but rather from the metadata.yaml file directly. Formating templates like these should be on the ignore list.

### Saxon HE 12

### Pagedjs & Pagedjs-cli

### Weasyprint

### Validation
