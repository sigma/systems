{
  lib,
  machine,
  ...
}:
with lib;
{
  config = mkIf machine.features.arbora {
    programs.aerospace.windowRules = mkBefore [
      {
        # Chrome suffixes the "arbora" profile's window title with "(arbora)".
        appId = "com.google.Chrome";
        layout = "tiling";
        windowTitleRegexSubstring = ".*\\(arbora\\)$";
        workspace = "W";
      }
    ];

    # Arbora's niks3 binary cache (arbora-partners/trunk#458). Added on top of
    # the shared substituter list, never replacing it. mkAfter: nix.conf is
    # applied in order, so these must follow the plain `substituters =` /
    # `trusted-public-keys =` lines (darwin-modules/nix.nix) or they get reset.
    nix.extraOptions = mkAfter ''
      extra-substituters = https://cache.arbora.partners
      extra-trusted-public-keys = cache.arbora.partners-1:41VKrT1uXYyuUKDb3t+TyyoBhabpUWaqdI6Xki+4c3U=
    '';

    # Reads are HTTP Basic. The credential is per-device, minted out of band
    # with `just cache-reader-mint` (arbora-partners/IaC), and never enters
    # this repo: it lives in /etc/nix/netrc (root-owned, 0600). That path is
    # also Nix's default netrc-file, so it works as-is without Determinate;
    # with Determinate it has to be merged into the daemon-managed netrc.
    determinate.additionalNetrcSources = mkIf machine.features.determinate [ "/etc/nix/netrc" ];

    homebrew.casks = [
      "brave-browser" # needed for the Google Cloud Console to work
      "notion"
      "notion-cli" # official Notion CLI, provides the `ntn` binary
      "notion-calendar"
    ];
  };
}
