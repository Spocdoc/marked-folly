Parser = require './parser'
Lexer = require './lexer'
InlineLexer = require './inline_lexer'

noOptions = {}

###
marked.defaults =
  noGfm: false
  noTables: false
  breaks: false
  pedantic: false
  sanitize: false
  smartLists: false
  smartypants: false
###

# WARN: may throw
module.exports = marked = (src, options=noOptions) ->
  src and Parser.parse Lexer.lex(src, options), options

marked['parser'] = marked.parser = Parser.parse
marked['lexer'] = marked.lexer = Lexer.lex
marked['inlineLexer'] = marked.inlineLexer = InlineLexer.output
marked['parse'] = marked.parse = marked
