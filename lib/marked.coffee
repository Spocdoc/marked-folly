block = require './block'
inline = require './inline'
utils = require './utils'
defs = require './defs'
_ = require 'lodash-fork'

regexEmptySpace = /^ +$/gm
regexIndentation = /\n*(\ *)/
regexLeadingPipes = /^ *\|? */gm
regexPipe = /\ *\|\ */
regexAlignRight = /^ *-+: *$/
regexAlignLeft = /^ *:-+ *$/
regexAlignCenter = /^ *:-+: *$/

LI_SPACE = 1
LI_BULLET = 2
LI_TEXT = 3
LI_PAR = 4

FENCE_LANG = 2
FENCE_TITLE = 3
FENCE_CODE = 4

TABLE_CAP_TOP = 1
TABLE_HEADER = 2
TABLE_ALIGN = 3
TABLE_ROWS = 4
TABLE_CAP_BOT = 5

class Marked
  constructor: (src) ->
    @html = @token defs(utils.normalize(src), @footnotes={}, @citations={}, @links={})

  toString: -> @html

  inlineLink: (cap, link) ->
    title = if link.title then " title=\"#{_.unsafeHtmlEscape(link.title)}\"" else ""
    if cap[0].charAt(0) isnt "!"
      "<a href=\"#{_.unsafeHtmlEscape(link.href,true)}\"#{title}>#{@inline(cap[1])}</a>"
    else
      "<img src=\"#{_.unsafeHtmlEscape(link.href,true)}\" alt=\"#{_.unsafeHtmlEscape(cap[1],true)}\" #{title} />"

  inline: (src) ->
    dst = ""
    while src

      # ESCAPE
      if cap = inline.escape.exec(src)
        src = src.substring(cap[0].length)
        dst += cap[1]
        continue

      # AUTOLINK
      if cap = inline.autolink.exec(src)
        src = src.substring(cap[0].length)
        if cap[2] is "@"
          text = (if cap[1][6] is ":" then utils.mangle(cap[1].substring(7)) else utils.mangle(cap[1]))
          href = utils.mangle("mailto:") + text
        else
          text = _.unsafeHtmlEscape(cap[1],true)
          href = text
        dst += "<a href=\"" + href + "\">" + text + "</a>"
        continue

      # URL
      if cap = inline.url.exec(src)
        src = src.substring(cap[0].length)
        text = _.unsafeHtmlEscape(cap[1],true)
        href = text
        dst += "<a href=\"" + href + "\">" + text + "</a>"
        continue

      # TAG
      if cap = inline.tag.exec(src)
        src = src.substring(cap[0].length)
        dst += _.unsafeHtmlEscape(cap[0],true) # to keep HTML, don't escape
        continue

      # LINK
      if cap = inline.link.exec(src)
        src = src.substring(cap[0].length)
        dst += @inlineLink cap,
          href: cap[2]
          title: cap[3]
        continue

      # REFLINK
      if (cap = inline.reflink.exec(src)) or (cap = inline.nolink.exec(src))
        src = src.substring(cap[0].length)
        link = (cap[2] or cap[1]).replace(/\s+/g, " ")
        link = @links[link.toLowerCase()]
        unless link and link.href
          dst += cap[0].charAt(0)
          src = cap[0].substring(1) + src
          continue
        dst += @inlineLink(cap, link)
        continue

      # STRONG
      if cap = inline.strong.exec(src)
        src = src.substring(cap[0].length)
        dst += "<strong>" + @inline(cap[2] or cap[1]) + "</strong>"
        continue

      # EM
      if cap = inline.em.exec(src)
        src = src.substring(cap[0].length)
        dst += "<em>" + @inline(cap[2] or cap[1]) + "</em>"
        continue

      # CODE
      if cap = inline.code.exec(src)
        src = src.substring(cap[0].length)
        dst += "<code>" + _.unsafeHtmlEscape(cap[2]) + "</code>"
        continue

      # BR
      if cap = inline.br.exec(src)
        src = src.substring(cap[0].length)
        dst += "<br />"
        continue

      # DEL
      if cap = inline.del.exec(src)
        src = src.substring(cap[0].length)
        dst += "<del>" + @inline(cap[1]) + "</del>"
        continue

      # TEXT
      if cap = inline.text.exec(src)
        src = src.substring(cap[0].length)
        dst += _.unsafeHtmlEscape(utils.smartypants(cap[0]), true)
        continue

      throw new Error("Infinite loop on byte: " + src.charCodeAt(0))  if src
    dst



  token: (src) ->
    dst = ''
    src = src.replace(regexEmptySpace, "")
    arr = undefined

    while src

      # NEWLINE
      if cap = block.newline.exec(src)
        src = src.substring(cap[0].length)

      # CODE
      if cap = block.code.exec(src)
        src = src.substring(cap[0].length)
        dst += "<pre><code>#{_.unsafeHtmlEscape cap[0].replace(/^ {4}/gm, "").replace(/\n+$/, "")}</code></pre>\n"
        continue

      # FENCES
      if cap = block.fences.exec(src)
        src = src.substring(cap[0].length)
        dst += "<pre><code class=\"lang-#{cap[FENCE_LANG]||''}\">#{_.unsafeHtmlEscape cap[FENCE_CODE]}</code></pre>\n"
        continue

      # HEADINGS
      if cap = block.heading.exec(src)
        src = src.substring(cap[0].length)
        dst += "<h#{cap[1].length}>#{@inline cap[2]}</h#{cap[1].length}>\n"
        continue

      # TABLE
      if cap = block.table.exec(src)
        src = src.substring(cap[0].length)
        dst += "<table>\n"
        dst += "<caption>#{@inline caption}</caption>\n" if caption = cap[TABLE_CAP_TOP] or cap[TABLE_CAP_BOT]

        (arr ||= []).length = 0
        for desc,i in cap[TABLE_ALIGN].split regexPipe
          if regexAlignLeft.test desc
            arr[i] = " style=\"text-align: left\""
          else if regexAlignCenter.test desc
            arr[i] = " style=\"text-align: center\""
          else if regexAlignRight.test desc
            arr[i] = " style=\"text-align: right\""
          else
            arr[i] = ""

        dst += "<thead>\n<tr>\n"
        for heading,i in header = cap[TABLE_HEADER].split regexPipe
          dst += "<th#{arr[i]||''}>#{@inline heading}</th>\n"
        dst += "</tr>\n</thead>\n"

        dst += "<tbody>\n"
        for row in cap[TABLE_ROWS].replace(regexLeadingPipes,'').split('\n')
          dst += "<tr>\n"
          dst += "<td#{arr[i]||''}>#{@inline cell}</td>\n" for cell, i in row.split regexPipe
          dst += "</tr>\n"

        dst += "</tbody>\n</table>\n"
        continue

      # UNDERLINED HEADING
      if cap = block.lheading.exec(src)
        src = src.substring(cap[0].length)
        depth = (if cap[2] is "=" then 1 else 2)
        dst += "<h#{depth}>#{@inline cap[1]}</h#{depth}>\n"
        continue

      # HR
      if cap = block.hr.exec(src)
        src = src.substring(cap[0].length)
        dst += "<hr />\n"
        continue

      # BLOCKQUOTE
      if cap = block.blockquote.exec(src)
        src = src.substring(cap[0].length)
        dst += "<blockquote>\n#{@token cap[0].replace(/^ *> ?/gm, "")}</blockquote>\n"
        continue

      # LISTS
      if ((cap = block.ol.exec src) and ordered = true) or
          ((cap = block.ul.exec src) and !(ordered = false))
        listText = cap[0]
        src = src.substring listText.length

        dst += if ordered then "<ol>\n" else "<ul>\n"

        hasPar = false

        i = (arr ||= []).length = 0
        while cap = block.item.exec listText
          arr[i++] = cap
          hasPar ||= !!cap[LI_PAR]

        for cap in arr
          if (indent = cap[LI_PAR].match regexIndentation) and indent = indent[1].length
            indent = maxIndent if indent > maxIndent = cap[LI_SPACE].length + 4
            cap[LI_PAR] = cap[LI_PAR].replace ///^\x20{#{indent}}///gm, ''

          dst += "<li>#{if hasPar then @token(cap[LI_TEXT])+@token(cap[LI_PAR]) else @inline(cap[LI_TEXT])}</li>\n"

        dst += if ordered then "</ol>\n" else "</ul>\n"
        continue

      # PARAGRAPH
      if cap = block.paragraph.exec(src)
        src = src.substring(cap[0].length)
        dst += "<p>#{@inline (if cap[1][cap[1].length - 1] is "\n" then cap[1].slice(0, -1) else cap[1])}</p>\n"
        continue

      throw new Error("Infinite loop on byte: " + src.charCodeAt(0))  if src

    dst

# WARN: may throw
module.exports = marked = (src) ->
  return src unless src
  new Marked src
