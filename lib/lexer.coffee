block = require './block'

regexNewline = /\r\n|\r|\u2424/g
regexTab = /\t/g
regexNbsp = /\u00a0/g
regexEmptySpace = /^ +$/gm

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
      if cap = block.newline.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push type: "space"  if cap[0].length > 1

      if cap = block.code.exec(src)
        src = src.substring(cap[0].length)
        cap = cap[0].replace(/^ {4}/gm, "")
        @tokens.push
          type: "code"
          text: cap.replace(/\n+$/, "")
        continue

      if cap = block.fences.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: "code"
          lang: cap[2]
          text: cap[3]
        continue

      if cap = block.heading.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: "heading"
          depth: cap[1].length
          text: cap[2]
        continue

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

      if cap = block.lheading.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: "heading"
          depth: (if cap[2] is "=" then 1 else 2)
          text: cap[1]
        continue

      if cap = block.hr.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push type: "hr"
        continue

      if cap = block.blockquote.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push type: "blockquote_start"
        cap = cap[0].replace(/^ *> ?/gm, "")
        @token cap, top
        @tokens.push type: "blockquote_end"
        continue

      if cap = block.list.exec(src)
        src = src.substring(cap[0].length)
        bull = cap[2]
        @tokens.push
          type: "list_start"
          ordered: bull.length > 1
        cap = cap[0].match(block.item)
        next = false
        l = cap.length
        i = 0
        while i < l
          item = cap[i]
          space = item.length
          item = item.replace(/^ *([*+-]|\d+\.) +/, "")
          if ~item.indexOf("\n ")
            space -= item.length
            item = item.replace(new RegExp("^ {1," + space + "}", "gm"), "")
          if i isnt l - 1
            b = block.bullet.exec(cap[i + 1])[0]
            if bull isnt b and not (bull.length > 1 and b.length > 1)
              src = cap.slice(i + 1).join("\n") + src
              i = l - 1
          loose = next or /\n\n(?!\s*$)/.test(item)
          if i isnt l - 1
            next = item[item.length - 1] is "\n"
            loose = next  unless loose
          @tokens.push type: (if loose then "loose_item_start" else "list_item_start")
          @token item, false
          @tokens.push type: "list_item_end"
          i++
        @tokens.push type: "list_end"
        continue

      if cap = block.html.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: (if @options['sanitize'] then "paragraph" else "html")
          pre: cap[1] is "pre" or cap[1] is "script"
          text: cap[0]
        continue

      if top and (cap = block.def.exec(src))
        src = src.substring(cap[0].length)
        @tokens.links[cap[1].toLowerCase()] =
          href: cap[2]
          title: cap[3]
        continue

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

      if top and (cap = block.paragraph.exec(src))
        src = src.substring(cap[0].length)
        @tokens.push
          type: "paragraph"
          text: (if cap[1][cap[1].length - 1] is "\n" then cap[1].slice(0, -1) else cap[1])
        continue

      if cap = block.text.exec(src)
        src = src.substring(cap[0].length)
        @tokens.push
          type: "text"
          text: cap[0]
        continue

      throw new Error("Infinite loop on byte: " + src.charCodeAt(0))  if src

    @tokens

