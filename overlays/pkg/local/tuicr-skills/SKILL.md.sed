# Applied to tuicr's skills/tuicr/SKILL.md by default.nix. Each expression
# rewrites or adds one passage so the skill matches the Rex floating-pane
# wrapper; the build fails if any of them misses (see the
# marker greps in default.nix). tuicr quits on `:q`; plain `q` no longer does.

# Frontmatter description.
s|^(description: .*)cmux, tmux, Zellij, or Herdr when|\1cmux, tmux, Zellij, Herdr, or Rex when|

# Rex: a floating pane over the agent's tab, blocking until tuicr exits.
/^\| `\$HERDR_ENV` is `1` \|/a\
| `$REX_SESSION` is set | Run `tuicr-wrapper-rex.sh /path/to/repo -- <scope>` |
/^<skill-directory>\/tuicr-wrapper-herdr\.sh /a\
<skill-directory>/tuicr-wrapper-rex.sh /path/to/repo -- -w
/^Herdr's JSON responses\.$/a\
\
The Rex wrapper opens tuicr in a Rex floating pane over the agent's tab and\
also requires `jq`.
s|the tmux, Zellij, and Herdr wrappers wait|the tmux, Zellij, Herdr, and Rex wrappers wait|
/^- Close tuicr: press `q`; the wrapper then closes the review pane$/a\
\
Rex:\
\
- Close tuicr: type `:q`; the floating pane closes and the wrapper returns\
- Minimize it with `alt+cmd+m` to look underneath; the wrapper keeps waiting\
- Only one review per tab: a second launch exits 75 while one is open
s|cmux/tmux/Zellij/Herdr available|cmux/tmux/Zellij/Herdr/Rex available|
