<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output method="xml" standalone="no"
        doctype-public="-//NLM//DTD JATS (Z39.96) Journal Publishing DTD with MathML3 v1.3 20210610//EN" 
        doctype-system="http://jats.nlm.nih.gov/publishing/1.3/JATS-journalpublishing1-3.dtd" indent="yes"/>
    
    <xsl:strip-space elements="*"/>
    
    <!-- PRIMARY TEMPLATES -->
    
    <!-- Copy all major parts and apply sub-templates -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="//boxed-text[starts-with(@specific-use, 'figure') and ./p]">
        <xsl:variable name="fig_id" select="replace(@specific-use,' ','-')"/>
        <fig id="{$fig_id}" position="float" orientation="portrait">
            <xsl:apply-templates select="*|node()">
                <xsl:sort select="position()"
                    data-type="number" order="descending"/>
            </xsl:apply-templates>
        </fig>
    </xsl:template>
    
    <xsl:template match="//boxed-text[starts-with(@specific-use, 'figure')]/p">
        <label><xsl:value-of select="substring-after(./parent::node()/@specific-use, ':')"/></label>
        <caption>
            <p><xsl:apply-templates select="@*|node()"/></p>
        </caption>
    </xsl:template>
    
    <xsl:template match="//boxed-text[starts-with(@specific-use, 'table') and parent::node()[name() = 'table-wrap']]/p">
        <label><xsl:value-of select="substring-after(./parent::node()/@specific-use, ':')"/></label>
        <caption>
            <p><xsl:apply-templates select="@*|node()"/></p>
        </caption>
    </xsl:template>
    
    <xsl:template match="//p[@specific-use='wrapper' and ./child::node()[starts-with(@specific-use, 'table')]]">
        <xsl:apply-templates select="./boxed-text/*" mode="specific-use"/>
    </xsl:template>

    <xsl:template match="//p[@specific-use='wrapper' and ./child::node()[starts-with(@specific-use, 'footnote text')]]">
        <xsl:apply-templates select="./boxed-text/*" mode="specific-use"/>
    </xsl:template>
    
    <xsl:template match="//table-wrap/boxed-text">
        <xsl:apply-templates select="@*|node()" />
    </xsl:template>
    
    <xsl:template match="//boxed-text/*" mode="specific-use">
        <xsl:copy>
            <xsl:attribute name="specific-use">
                <xsl:value-of select="../@specific-use" />
            </xsl:attribute>
            <xsl:apply-templates />
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="//table-wrap">
        <xsl:variable name="table_id" select="replace(./boxed-text/@specific-use,' ','-')"/>
        <table-wrap id="{$table_id}">
            <xsl:apply-templates select="@*|node()"/>
        </table-wrap>
    </xsl:template>
    
    <xsl:template match="//aff/*">
        <label>
            <xsl:value-of select="translate(./parent::node()/@id,'aff-','')"/>
        </label>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:template>
    
    <xsl:template match="license-p">
        <license-p>
            <xsl:apply-templates select="*"/>
            <xsl:value-of select="."/>
            <graphic mimetype="image"
                mime-subtype="png"
                xlink:href="./media/ccby.png"
                position="float"
                orientation="portrait"/>
        </license-p>
    </xsl:template>
    
    <xsl:template match="tex-math"></xsl:template>
    
    <xsl:template match="named-content[@content-type='citation_suggestion']">
        <xsl:value-of select="." disable-output-escaping="yes"/>
    </xsl:template>
</xsl:stylesheet>