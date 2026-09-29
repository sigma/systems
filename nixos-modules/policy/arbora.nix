{
  lib,
  machine,
  ...
}:
with lib;
{
  config = mkIf machine.features.arbora (
    mkMerge (
      [
        {
          # Arbora's niks3 binary cache (arbora-partners/trunk#458). Added on top
          # of the shared substituter list, never replacing it. mkAfter: nix.conf
          # is applied in order, so these must follow the plain `substituters =` /
          # `trusted-public-keys =` lines (nixos-modules/nix.nix) or they get
          # reset.
          nix.extraOptions = mkAfter ''
            extra-substituters = https://cache.arbora.partners
            extra-trusted-public-keys = cache.arbora.partners-1:41VKrT1uXYyuUKDb3t+TyyoBhabpUWaqdI6Xki+4c3U=
          '';
        }
      ]
      # Reads are HTTP Basic. The credential is per-device, minted out of band
      # with `just cache-reader-mint` (arbora-partners/IaC), and never enters this
      # repo: it lives in /etc/nix/netrc (root-owned, 0600). That path is also
      # Nix's default netrc-file, so it works as-is without Determinate; with
      # Determinate it has to be merged into the daemon-managed netrc.
      #
      # `optionals`, not `mkIf`: the Determinate module is imported only under
      # this feature (modules/registry.nix), so on a host without it the option
      # does not exist — and `mkIf false` would not save us, since pushDownProperties
      # keeps the attribute name and pushes the condition into the value.
      ++ optionals machine.features.determinate [
        { determinate.additionalNetrcSources = [ "/etc/nix/netrc" ]; }
      ]
    )
  );
}
