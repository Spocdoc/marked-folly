def = ///^
  \x20{0,3}

  \[([^\]]+)\]: # ref name

  \x20*

  ([\S\s]+?)

  \x20*
  $
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
    name = name.toLowerCase()
    switch name.charAt(0)
      when '#' then citations[name] = text
      when '^' then footnotes[name] = text
      else
        if matched = deflink.exec text
          links[name] =
            href: matched[1]
            title: matched[2]
    "\n"
