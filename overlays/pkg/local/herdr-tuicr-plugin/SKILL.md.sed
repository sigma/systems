# Applied to tuicr's skills/tuicr/SKILL.md by default.nix. Each expression
# rewrites one sentence that describes the upstream split-pane wrapper so the
# skill matches the popup one that replaces it; the build fails if none of
# them hit (see the grep in default.nix).
s|^The Herdr wrapper requires `jq` to read pane IDs and completion results from$|The Herdr wrapper opens tuicr in a Herdr popup (via the `tuicr` Herdr plugin)|
s|^Herdr's JSON responses\.$|rather than a split pane, and requires `jq` to read Herdr's JSON responses.|
s|^- Select a pane: click it in the Herdr UI$|- The popup is modal: it takes all keyboard input until tuicr exits|
s|^- Close tuicr: press `q`; the wrapper then closes the review pane$|- Close tuicr: press `q`; the popup closes itself and the wrapper returns|
