Parser = require './parser'
Lexer = require './lexer'
InlineLexer = require './inline_lexer'

# WARN: may throw
module.exports = marked = (src) ->
  src and Parser.parse Lexer.lex(src)

marked['parser'] = marked.parser = Parser.parse
marked['lexer'] = marked.lexer = Lexer.lex
marked['inlineLexer'] = marked.inlineLexer = InlineLexer.output
marked['parse'] = marked.parse = marked
