{merge, replace, escape} = require './utils'

noop = ->
noop.exec = ->

module.exports = block =
  newline: /^\n+/
  code: /^( {4}[^\n]+\n*)+/
  fences: noop
  hr: /^( *[-*_]){3,} *(?:\n+|$)/
  heading: /^ *(#{1,6}) *([^\n]+?) *#* *(?:\n+|$)/
  nptable: noop
  lheading: /^([^\n]+)\n *(=|-){3,} *\n*/
  blockquote: /^( *>[^\n]+(\n[^\n]+)*\n*)+/
  list: /^( *)(bull) [\s\S]+?(?:hr|\n{2,}(?! )(?!\1bull )\n*|\s*$)/
  html: /^ *(?:comment|closed|closing) *(?:\n{2,}|\s*$)/
  def: /^ *\[([^\]]+)\]: *<?([^\s>]+)>?(?: +["(]([^\n]+)[")])? *(?:\n+|$)/
  table: noop
  paragraph: /^((?:[^\n]+\n?(?!hr|heading|lheading|blockquote|tag|def))+)\n*/
  text: /^[^\n]+/

block.bullet = /(?:[*+-]|\d+\.)/
block.item = /^( *)(bull) [^\n]*(?:\n(?!\1bull )[^\n]*)*/
block.item = replace(block.item, "gm")(/bull/g, block.bullet)()
block.list = replace(block.list)(/bull/g, block.bullet)("hr", /\n+(?=(?: *[-*_]){3,} *(?:\n+|$))/)()
block._tag = "(?!(?:" + "a|em|strong|small|s|cite|q|dfn|abbr|data|time|code" + "|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo" + "|span|br|wbr|ins|del|img)\\b)\\w+(?!:/|@)\\b"
block.html = replace(block.html)("comment", /<!--[\s\S]*?-->/)("closed", /<(tag)[\s\S]+?<\/\1>/)("closing", /<tag(?:"[^"]*"|'[^']*'|[^'">])*?>/)(/tag/g, block._tag)()
block.paragraph = replace(block.paragraph)("hr", block.hr)("heading", block.heading)("lheading", block.lheading)("blockquote", block.blockquote)("tag", "<" + block._tag)("def", block.def)()

block.normal = merge({}, block)

block.gfm = merge {}, block.normal,
  fences: /^ *(`{3,}|~{3,}) *(\S+)? *\n([\s\S]+?)\s*\1 *(?:\n+|$)/
  paragraph: /^/

block.gfm.paragraph = replace(block.paragraph)("(?!", "(?!" + block.gfm.fences.source.replace("\\1", "\\2") + "|")()

block.tables = merge {}, block.gfm,
  nptable: /^ *(\S.*\|.*)\n *([-:]+ *\|[-| :]*)\n((?:.*\|.*(?:\n|$))*)\n*/
  table: /^ *\|(.+)\n *\|( *[-:]+[-| :]*)\n((?: *\|.*(?:\n|$))*)\n*/

