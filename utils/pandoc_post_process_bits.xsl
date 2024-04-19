<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="xs"
    version="2.0">

    <xsl:output method="xml" standalone="no"
        doctype-public="-//NLM//DTD BITS Book Interchange DTD v2.1 20220202//EN"
        doctype-system="https://jats.nlm.nih.gov/extensions/bits/2.1/BITS-book2-1.dtd" indent="yes" />

    <xsl:strip-space elements="*" />

    <!-- PRIMARY TEMPLATES -->

    <!-- Copy all major parts and apply sub-templates -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

    <!-- create chapters -->
    <xsl:template match="//book-body/sec">
        <xsl:variable name="chapter_id"
            select="count(preceding-sibling::*[name() = name(current())]) + 1" />
        <book-part id="chapter{$chapter_id}" book-part-type="chapter">
            <!-- <book-part-meta></book-part-meta> -->
            <body>
                <sec>
                    <xsl:apply-templates select="node()" />
                </sec>
            </body>
            <!-- <back></back> -->
        </book-part>
    </xsl:template>

    <!-- renove everything outside a chapter -->
    <xsl:template match="//book-body/*[not(self::sec)]"></xsl:template>

    <!-- handle references to other chapters -->
    <xsl:template match="xref[not(@ref-type)]">
        <xsl:variable name="chapter_id"
            select="count(ancestor::sec/preceding-sibling::*[name() = name(current())]) + 1" />
        <xref>
            <xsl:attribute name="rid">
                <xsl:text>chapter</xsl:text>
                <xsl:value-of select="count(//*[@id=current()/@rid]/preceding-sibling::*[name() = 'sec']) + 1"/>
            </xsl:attribute>
            <xsl:apply-templates select="node()" />
        </xref>
    </xsl:template>

</xsl:stylesheet>