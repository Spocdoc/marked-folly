block = require './block'

regexNewline = /\r\n|\r|\u2424/g
regexTab = /\t/g
regexNbsp = /\u00a0/g
regexEmptySpace = /^ +$/gm
regexIndentation = /\n*(\ *)/

LI_SPACE = 1
LI_BULLET = 2
LI_TEXT = 3
LI_PAR = 4

module.exports = class Lexer
  constructor: () ->
    @tokens = []
    @tokens.links = {}

  @lex: (src) -> (new Lexer).lex src

  lex: (src) ->
    @token src.replace(regexNewline, "\n").replace(regexTab, "    ").replace(regexNbsp, " "), true

  token: (src, top) ->
    src = src.replace(regexEmptySpace, "")

    while src

      # NEWLINE
      if cap = block.newline.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push type: "space"  if cap[0].length > 1

      # CODE
      if cap = block.code.exec(src)
        src = src.substring(cap[0].length)
        cap = cap[0].replace(/^ {4}/gm, "")
        @tokens.push
          type: "code"
          text: cap.replace(/\n+$/, "")
        continue

      # FENCES
      if cap = block.fences.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: "code"
          lang: cap[2]
          text: cap[3]
        continue

      # HEADINGS
      if cap = block.heading.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: "heading"
          depth: cap[1].length
          text: cap[2]
        continue

      # TABLE
      if top and (cap = block.nptable.exec(src))
        src = src.substring(cap[0].length)
        item =
          type: "table"
          header: cap[1].replace(/^ *| *\| *$/g, "").split(RegExp(" *\\| *"))
          align: cap[2].replace(/^ *|\| *$/g, "").split(RegExp(" *\\| *"))
          cells: cap[3].replace(/\n$/, "").split("\n")

        i = 0
        while i < item.align.length
          if /^ *-+: *$/.test(item.align[i])
            item.align[i] = "right"
          else if /^ *:-+: *$/.test(item.align[i])
            item.align[i] = "center"
          else if /^ *:-+ *$/.test(item.align[i])
            item.align[i] = "left"
          else
            item.align[i] = null
          i++
        i = 0
        while i < item.cells.length
          item.cells[i] = item.cells[i].split(RegExp(" *\\| *"))
          i++
        @tokens.push item
        continue

      # UNDERLINED HEADING
      if cap = block.lheading.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: "heading"
          depth: (if cap[2] is "=" then 1 else 2)
          text: cap[1]
        continue

      # HR
      if cap = block.hr.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push type: "hr"
        continue

      # BLOCKQUOTE
      if cap = block.blockquote.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push type: "blockquote_start"
        cap = cap[0].replace(/^ *> ?/gm, "")
        @token cap, top
        @tokens.push type: "blockquote_end"
        continue

      # LISTS
      if ~src.search block.listStart
        bullet = null

        while cap = src.match block.item
          src = src.substr cap[0].length

          cap[LI_BULLET] = 1 if cap[LI_BULLET].length > 1
          if cap[LI_BULLET] isnt bullet
            @tokens.push type: "list_end" if bullet?
            bullet = cap[LI_BULLET]
            @tokens.push
              type: "list_start"
              ordered: bullet is 1

          @tokens.push type: "list_item_start", hasPar: !!cap[LI_PAR]
          @token cap[LI_TEXT]
          if (indent = cap[LI_PAR].match regexIndentation) and indent = indent[1].length
            indent = maxIndent if indent > maxIndent = cap[LI_SPACE].length + 4
            cap[LI_PAR] = cap[LI_PAR].replace ///^\x20{#{indent}}///gm, ''
          @token cap[LI_PAR]
          @tokens.push type: "list_item_end"

        @tokens.push type: "list_end" if bullet?
        continue

      # HTML
      if cap = block.html.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: "paragraph" # or "html" if not sanitizing
          pre: cap[1] is "pre" or cap[1] is "script"
          text: cap[0]
        continue

      # LINK DEF
      if top and (cap = block.def.exec(src))
        src = src.substring(cap[0].length)
        @tokens.links[cap[1].toLowerCase()] =
          href: cap[2]
          title: cap[3]
        continue

      # TABLE
      if top and (cap = block.table.exec(src))
        src = src.substring(cap[0].length)
        item =
          type: "table"
          header: cap[1].replace(/^ *| *\| *$/g, "").split(RegExp(" *\\| *"))
          align: cap[2].replace(/^ *|\| *$/g, "").split(RegExp(" *\\| *"))
          cells: cap[3].replace(/(?: *\| *)?\n$/, "").split("\n")

        i = 0
        while i < item.align.length
          if /^ *-+: *$/.test(item.align[i])
            item.align[i] = "right"
          else if /^ *:-+: *$/.test(item.align[i])
            item.align[i] = "center"
          else if /^ *:-+ *$/.test(item.align[i])
            item.align[i] = "left"
          else
            item.align[i] = null
          i++
        i = 0
        while i < item.cells.length
          item.cells[i] = item.cells[i].replace(/^ *\| *| *\| *$/g, "").split(RegExp(" *\\| *"))
          i++
        @tokens.push item
        continue

      # PARAGRAPH
      if top and (cap = block.paragraph.exec(src))
        src = src.substring(cap[0].length)
        @tokens.push
          type: "paragraph"
          text: (if cap[1][cap[1].length - 1] is "\n" then cap[1].slice(0, -1) else cap[1])
        continue

      # TEXT
      if cap = block.text.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: "text"
          text: cap[0]
        continue

      throw new Error("Infinite loop on byte: " + src.charCodeAt(0))  if src

    @tokens

