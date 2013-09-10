inline = require './inline'
u = require './utils'

module.exports = class InlineLexer
  constructor: (@links) ->
    throw new Error("Tokens array requires a `links` property.")  unless @links

  @output: (src, links) ->
    (new InlineLexer(links)).output src

  outputLink: (cap, link) ->
    if cap[0][0] isnt "!"
      "<a href=\"" + u.escape(link.href) + "\"" + ((if link.title then " title=\"" + u.escape(link.title) + "\"" else "")) + ">" + @output(cap[1]) + "</a>"
    else
      "<img src=\"" + u.escape(link.href) + "\" alt=\"" + u.escape(cap[1]) + "\"" + ((if link.title then " title=\"" + u.escape(link.title) + "\"" else "")) + ">"

  smartypants: (text) ->
    # TODO: allow escaping the currency symbols, precompile the regex
    text
      .replace(/<-{1,2}>/g, '&harr;')
      .replace(/-->/g, '&rarr;')
      .replace(/<--/g, '&larr;')
      .replace(/--/g, "&mdash;")
      .replace(/-(?!\S)/g, '&minus;')
      .replace(/L(?=\d)/g, '&pound;')
      .replace(/E(?=\d)/g, '&euro;')
      .replace(/Y(?=\d)/g, '&yen;')
      .replace(/\([cC]\)/g, '&copy;')
      .replace(/\([rR]\)/g, '&reg;')
      .replace(/\s?\((?:TM|tm)\)/g, '&trade;')
      .replace(/'([^']*)'/g, "&lsquo;$1&rsquo;")
      .replace(/"([^"]*)"/g, "&ldquo;$1&rdquo;")
      .replace(/\.{3}/g, "&hellip;")

  mangle: (text) ->
    out = ""
    l = text.length
    i = 0
    while i < l
      ch = text.charCodeAt(i)
      ch = "x" + ch.toString(16)  if Math.random() > 0.5
      out += "&#" + ch + ";"
      i++
    out

  output: (src) ->
    out = ""
    while src
      if cap = inline.escape.exec(src)
        src = src.substring(cap[0].length)
        out += cap[1]
        continue
      if cap = inline.autolink.exec(src)
        src = src.substring(cap[0].length)
        if cap[2] is "@"
          text = (if cap[1][6] is ":" then @mangle(cap[1].substring(7)) else @mangle(cap[1]))
          href = @mangle("mailto:") + text
        else
          text = u.escape(cap[1])
          href = text
        out += "<a href=\"" + href + "\">" + text + "</a>"
        continue
      if cap = inline.url.exec(src)
        src = src.substring(cap[0].length)
        text = u.escape(cap[1])
        href = text
        out += "<a href=\"" + href + "\">" + text + "</a>"
        continue
      if cap = inline.tag.exec(src)
        src = src.substring(cap[0].length)
        # out += (if @options['sanitize'] then u.escape(cap[0]) else cap[0])
        out += u.escape(cap[0])
        continue
      if cap = inline.link.exec(src)
        src = src.substring(cap[0].length)
        out += @outputLink(cap,
          href: cap[2]
          title: cap[3]
        )
        continue
      if (cap = inline.reflink.exec(src)) or (cap = inline.nolink.exec(src))
        src = src.substring(cap[0].length)
        link = (cap[2] or cap[1]).replace(/\s+/g, " ")
        link = @links[link.toLowerCase()]
        if not link or not link.href
          out += cap[0][0]
          src = cap[0].substring(1) + src
          continue
        out += @outputLink(cap, link)
        continue
      if cap = inline.strong.exec(src)
        src = src.substring(cap[0].length)
        out += "<strong>" + @output(cap[2] or cap[1]) + "</strong>"
        continue
      if cap = inline.em.exec(src)
        src = src.substring(cap[0].length)
        out += "<em>" + @output(cap[2] or cap[1]) + "</em>"
        continue
      if cap = inline.code.exec(src)
        src = src.substring(cap[0].length)
        out += "<code>" + u.escape(cap[2], true) + "</code>"
        continue
      if cap = inline.br.exec(src)
        src = src.substring(cap[0].length)
        out += "<br />"
        continue
      if cap = inline.del.exec(src)
        src = src.substring(cap[0].length)
        out += "<del>" + @output(cap[1]) + "</del>"
        continue
      if cap = inline.text.exec(src)
        src = src.substring(cap[0].length)
        out += u.escape(@smartypants(cap[0]))
        continue
      throw new Error("Infinite loop on byte: " + src.charCodeAt(0))  if src
    out

