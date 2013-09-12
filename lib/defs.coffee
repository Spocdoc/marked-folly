def = ///^
  \[([^\]]+)\]: # ref name

  \x20*

  ([\S\s]+?)

  \x20*
  (?:\n+|$) # end of line

///gm

deflink = ///^
  <?
    ( [\S\s]+? )
  >? # URL

  (?:
    \x20+
    ["(]
    ([^\n]+)
    [")]
  )? # optional title

  \x20*$
  ///

module.exports = (src, footnotes, citations, links) ->
  src.replace def, (matched, name, text) ->
    switch name.charAt(0)
      when '#' then citations[name] = text
      when '^' then footnotes[name] = text
      else
        if matched = deflink.exec text
          links[name] = matched[1]
    ""