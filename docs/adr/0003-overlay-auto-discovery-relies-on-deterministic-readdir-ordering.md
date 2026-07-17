# Overlay auto-discovery relies on deterministic `readDir` ordering

`overlays/pkg/default.nix` discovers every `*.nix` sibling and composes them with
`foldl' (flip extends)` in `builtins.attrNames (builtins.readDir ./.)` order. We
deliberately keep this auto-discovery and do **not** impose an explicit composition
order, because the two facts that would make explicit ordering necessary do not hold
here: `attrNames` is guaranteed sorted, so the order is deterministic and reproducible
(alphabetical by filename, not filesystem- or machine-dependent); and `extends` *stacks*
overlays rather than picking a winner — a later overlay receives the earlier overlays'
result as `prev`, so two files that both touch a package via `prev.foo.overrideAttrs`
both apply. The only case where order could silently drop a change is an overlay that
*clobbers* `prev` (e.g. `foo = final.callPackage ./foo.nix {}` ignoring `prev`), and
explicit ordering would not fix that either — it is a code-review concern, not an
architecture-ordering one.

## Status

accepted

## Considered Options

An automated architecture review (2026-07-17) recommended prepending an explicit
priority list for overlays that must precede others, on the premise that `readDir` order
is undefined and a collision winner would be "filesystem-dependent." We rejected this:
the premise is incorrect for Nix (`attrNames` is sorted), no two overlay files currently
define the same attribute, and composable (`prev`-based) overlays make collisions
harmless regardless of order. Recorded here so the recommendation is not re-raised the
next time someone reads `readDir` and assumes nondeterminism.
