bullet = "(?:[*+-]|\\d+\\.)"
bulletOnly = "[*+-]"
number = "\\d+\\."
hr = "( *[-*_]){3,} *(?:\\n+|$)"
heading = " *(\#{1,6}) *([^\\n]+?) *#* *(?:\\n+|$)"
lheading = "([^\\n]+)\\n *(=|-){3,} *\\n*"
blockquote = "( *>[^\n]+(\n[^\n]+)*\n*)+"
def = """ *\\[([^\\]]+)\\]: *<?([^\\s>]+)>?(?: +["(]([^\\n]+)[")])? *(?:\\n+|$)"""
fences = """ *(`{3,}|~{3,}) *(\\S+)? *(?:\\[([^\n]*)\\])?\\n([\\s\\S]+?)\\s*\\1 *(?:\\n+|$)"""
listStart = "\\x20*#{bullet}\\x20[\\s\\S]+"

module.exports =
  ul: ///^
    (\x20*) (#{bulletOnly}) \x20 [\s\S]+?
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
      \n+\1\x20{1,4}[^\n]*
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
          |#{def}
          |#{fences.replace '\\1', '\\2'}
          |#{listStart}
        )
      )+
    )\n*
    ///

  code: /^(\n* {4}[^\n]+)+/

  table: ///^\x20*
    # title
    (?:
      \[
        ([^\n]*) # title string
      \]
      \x20*\n
    )?

    # header
    \x20* \|? \x20* (.* \| .*?) \|? \x20*\n

    # align
    \x20* \|? \x20* ([-:]+ [-\x20|:]*?) \|? \x20* \n+

    # rows
    (
      (?:
        \x20* \|? .* \| .* (?:\n|$)
      )*
    )

    (?:
      \n
      \[
        ([^\n]*) # title string
      \]
      \x20*\n
    )?

    \n*
  ///

