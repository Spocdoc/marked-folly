module.exports =
  linePositions: (text) ->
    offsets = [0]
    i = 1
    text.replace /\n/g, (match, offset) -> offsets[i++] = offset+1
    offsets

  numLines: (text) ->
    text.split('\n').length

  normalize: do ->
    regexNewline = /\r\n|\r|\u2424/g
    regexTab = /\t/g
    regexNbsp = /\u00a0/g
    (text) ->
      text
        .replace(regexNewline, "\n")
        .replace(regexTab, "    ")
        .replace(regexNbsp, " ")

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

  smartypants: (text) ->
    # TODO some replacements throw off the character positions
    text
      # .replace(/<--?>/g, '&harr;')
      # .replace(/-->/g, '&rarr;')
      # .replace(/<--/g, '&larr;')
      # .replace(/--/g, "&mdash;")
      # .replace(/-(?!\S)/g, '&minus;')
      # .replace(/\bL(?=\d)/g, '&pound;')
      # .replace(/\bE(?=\d)/g, '&euro;')
      # .replace(/\bY(?=\d)/g, '&yen;')
      # .replace(/\([cC]\)/g, '&copy;')
      # .replace(/\([rR]\)/g, '&reg;')
      # .replace(/\s?\((?:TM|tm)\)/g, '&trade;')
      .replace(/(\w)'(\w)/g, "$1&rsquo;$2")
      .replace(/(\w)"(\w)/g, "$1&rdquo;$2")
      .replace(/'([^']*)'/g, "&lsquo;$1&rsquo;")
      .replace(/"([^"]*)"/g, "&ldquo;$1&rdquo;")
      # .replace(/\.{3}/g, "&hellip;")
      .replace(/\ \ /g, "&nbsp; ")
