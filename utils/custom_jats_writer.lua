-- Lua string.gmatch regex patterns: https://www.fhug.org.uk/kb/kb-article/understanding-lua-patterns/
function Writer (doc, opts)
    local filter = {
        Div = function (div)
            -- process custom styles
            -- 1) Identify elements with custom styles based on the data provided in doc.meta.process (from metadata.yaml).
            -- 2) Process them and rewrite elements or store metadata in doc.meta 
            -- 3) Mark processed elements as "Remove", remove elements not needed 
            --    and move style information of elements processed later (xslt) to the 
            --    Jats 'specific-use' attribute
            if div.attr.attributes['custom-style'] then
                -- process styles containing metadata
                processStyles = Table2Array(doc.meta.processStyles)
                local styles = Set({
                    processStyles['title'],
                    processStyles['abstract'],
                    processStyles['authorNames'],
                    processStyles['affiliations'],
                    processStyles['corresp'],
                    processStyles['keywords'],
                    processStyles['subject'], -- equals sections in OJS
                    processStyles['table-turn-right'],
                    processStyles['table-turn-left']
                })
                -- process custom metadata styles taken from docx
                if styles[div.attr.attributes['custom-style']] then
                    -- Author Names, ...
                    if (div.attr.attributes['custom-style'] == processStyles['authorNames']) then
                        -- because we are concatenating strings later we need to initialize them
                        authorArray = {
                            surname = "",
                            ["given-names"] = "",
                            email = "",
                            affiliation = {},
                            ["cor-id"] = ""
                        }
                        sep = ""
                        authors = {}
                        for i, item in ipairs(div.content[1].content) do
                            if item ~= pandoc.Space() then
                                -- if its a Superscript it should be the affiliation value
                                -- it should also be the end of the authors name
                                if item.t == "Superscript" then
                                    for a, aff in ipairs(item.content) do
                                        if aff ~= pandoc.Space() then
                                            dummy = (aff.text):gsub(",", "")
                                            table.insert(authorArray.affiliation, dummy)
                                        end
                                    end
                                    table.insert(authors, authorArray)
                                    authorArray = {
                                        surname = "",
                                        ["given-names"] = "",
                                        email = "",
                                        affiliation = {},
                                        ["cor-id"] = ""
                                    }
                                    sep = ""
                                else
                                    -- if its not Superscript it should be a string we can parse for the name
                                    if item.t == "Str" then
                                        local separators = Set({",","&"})
                                        if separators[item.text] then
                                            -- skip separator characters
                                        else
                                            -- copy author name, we expect the last name to be the surname
                                            authorArray["given-names"] = authorArray["given-names"]..sep..authorArray.surname
                                            authorArray.surname = item.text
                                            sep = " "
                                        end
                                    end
                                end
                            end
                        end
                        doc.meta.author = authors
                    end
                    -- Author Affiliations
                    if (div.attr.attributes['custom-style'] == processStyles['affiliations']) then
                        affiliationArray = {}
                        if div.content[1].content[1].t == "Superscript" then
                            affiliationArray["id"] = pandoc.utils.stringify(div.content[1].content:remove(1))
                            affiliationArray["organization"] = pandoc.utils.stringify(div.content[1].content)
                        end
                        table.insert(opts.variables.affiliation, affiliationArray)
                    end
                    -- Corresponding Author
                    if (div.attr.attributes['custom-style'] == processStyles['corresp']) then
                        -- set the authors "cor-id" field and extract the email

                        -- we have one pre-configured "cor-id" in metadata.yaml, just need to set the email
                        email = string.gmatch(pandoc.utils.stringify(div.content[1].content), "[%w%s.-]+@[%w.-]+%.[%w]+")()
                        doc.meta.article["author-notes"].corresp[1].email = pandoc.Inlines(email)

                        -- we have to identify the corresponding author by name
                        -- get the surnames of all authors and search the corresponding string
                        for k, v in ipairs(doc.meta.author) do
                            if string.find(pandoc.utils.stringify(div.content[1].content), v.surname) then
                                v["cor-id"] = 1
                            end
                        end
                    end
                    -- Title
                    if (div.attr.attributes['custom-style'] == processStyles['title']) then
                        doc.meta.title = div.content[1].content
                    end
                    -- Subject (Article, Editorial, ...)
                    if (div.attr.attributes['custom-style'] == processStyles['subject']) then
                        doc.meta.article.heading = div.content[1].content
                    end
                    -- Abstract
                    if (div.attr.attributes['custom-style'] == processStyles['abstract']) then
                        if (pandoc.utils.stringify(div.content[1]) ~= "Abstract") then
                            if doc.meta.abstract == nil then
                                doc.meta.abstract = pandoc.Blocks(div.content)
                            else
                                doc.meta.abstract = doc.meta.abstract..div.content
                            end
                        else
                            doc.meta.abstract = nil
                        end
                    end
                    -- keywords
                    if (div.attr.attributes['custom-style'] == processStyles['keywords']) then
                        if (pandoc.utils.stringify(div.content[1].content[1]) ~= processStyles['keywords']) then
                            -- split keyword(tag) string at ',' or ';' and remove trailing and leading spaces
                            tags = {}
                            local i = 1
                            for tag in string.gmatch(pandoc.utils.stringify(div.content[1].content), "%s*([^,;]+)%s*") do
                                tags[i] = tag
                                i = i + 1
                            end
                            doc.meta.tags = pandoc.List(tags)
                        end
                    end
                    -- handle table rotation styles
                    if (div.attr.attributes['custom-style'] == processStyles['table-turn-right']) then
                        div.attr.attributes['specific-use'] = "table-turn-right"
                        return div
                    end
                    if (div.attr.attributes['custom-style'] == processStyles['table-turn-left']) then
                        div.attr.attributes['specific-use'] = "table-turn-left"
                        return div
                    end
                    -- mark handled divs to remove later
                    div.attr.attributes['custom-style'] = Null
                    div.content[1] = pandoc.Str("REMOVE")
                    return div
                end
                -- remove custom styles not taken from docx (i.e. metadata that will be provided by OJS) 
                local styles = Set(Table2Array(doc.meta.ignoreStyles))
                if styles[div.attr.attributes['custom-style']] then
                    div.content[1] = Null
                    return div.content
                end
                -- remove wrapper divs
                local styles = Set({
                    'List Paragraph',
                    'Quote'
                })
                -- return plain content for all other processed styles
                if styles[div.attr.attributes['custom-style']] then
                    return div.content
                end
                -- set figure label
                local styles = Set({pandoc.utils.stringify(doc.meta.figureLabel), processStyles['figure-caption']})
                if styles[div.attr.attributes['custom-style']] then
                    if (div.attr.attributes['custom-style'] == pandoc.utils.stringify(doc.meta.figureLabel)) then
                        -- count number of figures
                        figCount = figCount + 1
                        div.attr.attributes['specific-use'] = 'figure'..figCount..':'..pandoc.utils.stringify(doc.meta.figureLabel)..' '..figCount
                    else
                        -- remove Word figure label
                        div.content[1].content:remove(1)
                        div.content[1].content:remove(1)
                        div.content[1].content:remove(1)
                        div.content[1].content:remove(1)
                        div.attr.attributes['specific-use'] = 'figure'
                    end
                    return div
                end
                -- set table label
                local styles = Set({processStyles['table-caption']})
                if styles[div.attr.attributes['custom-style']] then
                    -- count number of tables
                    tableCount = tableCount + 1
                    div.attr.attributes['specific-use'] = 'table '..tableCount..':'..pandoc.utils.stringify(doc.meta.tableLabel)..' '..tableCount
                    -- remove Word table label (and Spaces)
                    div.content[1].content:remove(1)
                    div.content[1].content:remove(1)
                    div.content[1].content:remove(1)
                    div.content[1].content:remove(1)
                    return div
                end
                -- set specific-use for remaining divs
                div.attr.attributes['specific-use'] = div.attr.attributes['custom-style']
                return div
            end
            return div
        end,
        Span = function (span)
            -- process custom styles
            -- set to  Jats 'specific-use' attribute
            if span.attr.attributes['custom-style'] then
                span.attr.attributes['specific-use'] = span.attr.attributes['custom-style']
                return span
            end
        end,
        
        Meta = function(meta)
            meta = doc.meta
            return meta
        end
    }
    
    figCount = 0;
    tableCount = 0;
    opts.variables.affiliation = {}
    
    d = doc:walk(filter)

    -- debugPrint(d.meta, "d.meta")
    -- debugPrint(doc.meta, "doc.meta")

    local jats = pandoc.write(d, 'jats+element_citations', opts)

    -- combine boxed-text graphic and caption paragraph
    jats = jats:gsub('</boxed%-text>\n%s+<boxed%-text specific%-use="figure">\n%s+','  ')

    -- combine boxed-text table label with table-wrap
    jats = jats:gsub('<boxed%-text specific%-use="table ','<table-wrap>\n        <boxed-text specific-use="table')
    jats = jats:gsub('</boxed%-text>\n%s+<table%-wrap>','  </boxed-text>');
    jats = jats:gsub('dtd%-version="1.2"','dtd-version="1.3"');

    -- add volume and issue tags after pub-date
    jats = jats:gsub('</pub%-date>',
        '</pub-date><volume>'..pandoc.utils.stringify(doc.meta.journal['volume'])..
        '</volume><issue>'..pandoc.utils.stringify(doc.meta.journal['issue'])..'</issue>');

    -- remove boxed-text tags from custom-style paragarphs
    jats = jats:gsub('\n<boxed%-text>\n%s%s<p>REMOVE</p>\n</boxed%-text>','');
    
    return jats
end

function Set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

-- Returns a complete copy of a pandoc metadata table with values as strings
-- used for settings variables to overwrite pandoc metadata
function Table2Array(table)
    local buffer = {}

    for k,v in pairs(table) do
        buffer[k] = pandoc.utils.stringify(v)
    end
    return buffer
end

function debugPrint(item, label)
    local keyset={}
    local n=0

    print("### "..label.." => "..type(item)..":"..pandoc.utils.type(item).." ###")
    local label = "  "..label

    if type(item) ~= "string" then
        for k,v in pairs(item) do
            n=n+1
            keyset[n]=k
            print("|** ".."  "..k.." => "..type(v)..":"..pandoc.utils.type(v).." ***")
            if type(v) == "table" then
                if (pandoc.utils.type(v) == 'Inlines') then
                    debugPrintString(v, label.."."..k)
                else
                    debugPrint(v, label.."."..k)
                end
            elseif type(v) == "function" then
                print(item)
            elseif pandoc.utils.type(v) == "blocks" then
                print("WE HAVE BLOCKS")
                print(v)
            elseif pandoc.utils.type(v) == "Doc" then
                print(v)
            else
                debugPrintString(v, "|-- "..label.."."..k)
            end
        end
    else
        debugPrintString(item, label)
    end
    return keyset
end

function debugPrintString(item, label) 
    print(label..": "..pandoc.utils.type(item)..": "..pandoc.utils.stringify(item))
end