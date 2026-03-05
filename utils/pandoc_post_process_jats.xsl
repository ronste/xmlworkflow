<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:cfg="urn:xmlworkflow:jats:config"
    exclude-result-prefixes="xs cfg"
    version="2.0">

    <xsl:param name="resource-uri" as="xs:string" select="'pandoc_post_process_jats.resources.xml'"/>
    <xsl:variable name="resource-doc"
        select="if (doc-available(resolve-uri($resource-uri, static-base-uri())))
                then doc(resolve-uri($resource-uri, static-base-uri()))
                else ()"/>

    <xsl:function name="cfg:get" as="xs:string">
        <xsl:param name="key" as="xs:string"/>
        <xsl:param name="default" as="xs:string"/>
        <xsl:sequence
            select="string((
                $resource-doc/resources/entry[@key = $key]/@value,
                $default
            )[1])"/>
    </xsl:function>
    
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
    
    <!-- handle figures -->
    <!-- Number and normalize figures based on document order and extract caption text from Pandoc boxed-text wrapper -->
    <xsl:template match="//fig[caption/boxed-text[starts-with(@specific-use, 'figure')]]">
        <xsl:variable name="figure-prefix" select="cfg:get('specific-use.figure-prefix', 'figure')"/>
        <xsl:variable name="bibr-ref-type" select="cfg:get('xref.ref-type.bibr', 'bibr')"/>
        <xsl:variable name="label-delimiter" select="cfg:get('caption.label-delimiter', '#')"/>
        <xsl:variable name="figure-id-prefix" select="cfg:get('id.figure-prefix', 'figure-')"/>
        <xsl:variable name="fig_num" select="count(preceding::fig[caption/boxed-text[starts-with(@specific-use, $figure-prefix)]]) + 1"/>
        <xsl:variable name="fig_specific_use" select="string(caption/boxed-text[starts-with(@specific-use, $figure-prefix)][1]/@specific-use)"/>
        <xsl:variable name="fig_ref_alt" select="string((preceding::xref[not(@ref-type = $bibr-ref-type)][matches(normalize-space(@alt), concat('^.+\s+', $fig_num, '$'))][1]/@alt, following::xref[not(@ref-type = $bibr-ref-type)][matches(normalize-space(@alt), concat('^.+\s+', $fig_num, '$'))][1]/@alt)[1])"/>
        <xsl:variable name="fig_prefix" select="replace(normalize-space($fig_ref_alt), '\s+[0-9]+$', '')"/>
        <xsl:variable name="fig_label" select="if (contains($fig_specific_use, $label-delimiter)) then substring-after($fig_specific_use, $label-delimiter) else if (string-length($fig_prefix) &gt; 0) then concat($fig_prefix, ' ', $fig_num) else string($fig_num)"/>
        <xsl:variable name="fig_caption" select="normalize-space(string-join(caption/boxed-text[starts-with(@specific-use, $figure-prefix)]//text(), ' '))"/>
        <fig id="{concat($figure-id-prefix, $fig_num)}">
            <xsl:apply-templates select="@*[name() != 'id']"/>
            <label>
                <xsl:value-of select="$fig_label"/>
            </label>
            <caption>
                <p>
                    <xsl:value-of select="$fig_caption"/>
                </p>
            </caption>
            <xsl:apply-templates select="node()[not(self::caption)]"/>
        </fig>
    </xsl:template>

    <!-- Skip figure caption helper wrappers to prevent duplication -->
    <xsl:template match="//boxed-text[starts-with(@specific-use, 'figure')]"/>
    
    <!-- handle tables -->
    <!-- combine table caption, label and content into table-wrap !!! This should actually be handled by Pandoc !!! -->
    <xsl:template match="//table-wrap[not(caption)]">

        <xsl:variable name="table-prefix" select="cfg:get('specific-use.table-prefix', 'table')"/>
        <xsl:variable name="label-delimiter" select="cfg:get('caption.label-delimiter', '#')"/>

        <xsl:variable name="caption_before" select="preceding-sibling::*[1][local-name() = 'boxed-text' and starts-with(@specific-use, $table-prefix)]"></xsl:variable>
        <xsl:variable name="caption_after" select="following-sibling::*[1][local-name() = 'boxed-text' and starts-with(@specific-use, $table-prefix)]"></xsl:variable>

        <xsl:variable name="caption" select="concat($caption_before, $caption_after)"/>
        <xsl:variable name="caption_label" select="concat($caption_before/@specific-use, $caption_after/@specific-use)"/>
        
        <xsl:variable name="table_id" select="replace(substring-before($caption_label, $label-delimiter),' ','-')"/>
        <table-wrap id="{$table_id}">
            <xsl:apply-templates select="@*"/>
            <label><xsl:value-of select="substring-after($caption_label, $label-delimiter)"/></label>
            <caption>
                <p>
                    <xsl:value-of select="$caption"/>
                </p>
            </caption>
            <xsl:apply-templates select="node()"/>
        </table-wrap>
    </xsl:template>

    <!-- Skip boxed-text[starts-with(@specific-use, 'table')] to prevent duplication, this is handled in //table-wrap -->
    <xsl:template match="//boxed-text[starts-with(@specific-use, 'table')]"/>
    
    <!-- handle affiliations -->
    <!-- RS: required -->
    <xsl:template match="//aff/*">
        <xsl:variable name="aff-id-prefix" select="cfg:get('id.aff-prefix', 'aff-')"/>
        <label>
            <xsl:value-of select="replace(string(./parent::node()/@id), concat('^', $aff-id-prefix), '')"/>
        </label>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:template>

    <!-- handle Pandoc specific-use wrapper / boxed-text -->
    <!-- These are created by Pandoc styles filter by default and we need to remove or handle them -->
    <!-- 5.3.2026: Discussed with Albert: Styles should be provided as specific-use attribute (see HTML). Will be revised  -->
    <!-- RS: required -->

    <!--  and ./child::node()[starts-with(@specific-use, 'footnote text')] -->
    <xsl:template match="//p[@specific-use='wrapper']">
        <xsl:apply-templates select="./boxed-text/*" mode="specific-use"/>
    </xsl:template>

    <xsl:template match="//boxed-text/*" mode="specific-use">
        <xsl:copy>
            <xsl:attribute name="specific-use">
                <xsl:value-of select="../@specific-use" />
            </xsl:attribute>
            <xsl:apply-templates />
        </xsl:copy>
    </xsl:template>

    <!-- handle other stuff -->

    <!-- handle license-p element: combine text with license image -->
    <!-- RS: required -->
    <xsl:template match="license-p">
        <xsl:variable name="ccby-image-href" select="cfg:get('license.ccby.href', './media/ccby.png')"/>
        <license-p>
            <xsl:apply-templates select="*"/>
            <xsl:value-of select="."/>
            <graphic mimetype="image"
                mime-subtype="png"
                xlink:href="{$ccby-image-href}"
                position="float"
                orientation="portrait"/>
        </license-p>
    </xsl:template>
    
    <!-- remove named-content wrapper around citationSuggestion -->
    <!-- RS: required -->
    <xsl:template match="named-content[@content-type='citationSuggestion']">
        <xsl:value-of select="." disable-output-escaping="yes"/>
    </xsl:template>

    <!-- remove all tags already handle in custom lua writer -->
    <!-- RS: required -->
    <xsl:template match="boxed-text[@specific-use='REMOVE']"></xsl:template>

</xsl:stylesheet>