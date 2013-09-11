bullet = "(?:[*+-]|\\d+\\.)"
bulletOnly = "[*+-]"
number = "\\d+\\."
hr = "( *[-*_]){3,} *(?:\\n+|$)"
tag = "(?!(?:a|em|strong|small|s|cite|q|dfn|abbr|data|time|code|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo|span|br|wbr|ins|del|img)\\b)\\w+(?!:/|@)\\b"
comment = "<!--[\\s\\S]*?-->"
closed = "<(#{tag})[\\s\\S]+?<\\/\\1>"
closing = """<#{tag}(?:"[^"]*"|'[^']*'|[^'">])*?>"""
heading = " *(\#{1,6}) *([^\\n]+?) *#* *(?:\\n+|$)"
lheading = "([^\\n]+)\\n *(=|-){3,} *\\n*"
blockquote = "( *>[^\n]+(\n[^\n]+)*\n*)+"
def = """ *\\[([^\\]]+)\\]: *<?([^\\s>]+)>?(?: +["(]([^\\n]+)[")])? *(?:\\n+|$)"""
fences = """ *(`{3,}|~{3,}) *(\\S+)? *(?:\\[([^\n]*)\\])?\\n([\\s\\S]+?)\\s*\\1 *(?:\\n+|$)"""
listStart = "\\x20*#{bullet}\\x20[\\s\\S]+"

module.exports =
  ul: ///^
    (\x20*) #{bulletOnly} \x20 [\s\S]+?
    (?:
      \n(?!(?:\1\x20|\1\2|\n))
      |$
    )
    ///

  ol: ///^
    (\x20*) #{number} \x20 [\s\S]+?
    (?:
      \n(?!(?:\1\x20|\1#{number}|\n))
      |$
    )
    ///

  item: ///^\n*
    (\x20*) (#{bullet}) \x20+ ([^\n]*)
    ((?:
      \n+#{bullet}\x20{1,4}[^\n]*
    )*)
    ///gm

  hr: ///^#{hr}///
  newline: /^\n+/

  text: /^[^\n]+/

  heading: ///^#{heading}///
  lheading: ///^#{lheading}///
  blockquote: ///^#{blockquote}///
  def: ///^#{def}///
  fences: ///^#{fences}///

  paragraph: ///^
    (
      (?:
        [^\n]+\n?
        (?!
          #{hr}
          |#{heading}
          |#{lheading}
          |#{blockquote}
          |<#{tag}
          |#{def}
          |#{fences.replace '\\1', '\\2'}
          |#{listStart}
        )
      )+
    )\n*
    ///

  code: /^( {4}[^\n]+\n*)+/

  html: ///^
    \x20*
    (?:#{comment}|#{closed}|#{closing})
    \x20*
    (?:\n{2,}|\s*$)
    ///

  nptable: /^ *(\S.*\|.*)\n *([-:]+ *\|[-| :]*)\n((?:.*\|.*(?:\n|$))*)\n*/
  table: /^ *\|(.+)\n *\|( *[-:]+[-| :]*)\n((?: *\|.*(?:\n|$))*)\n*/

