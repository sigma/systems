{
  inputs,
  config,
  ...
}:
final: prev:
let
  system = final.stdenv.system;
  nixpkgs-stable = if final.stdenv.isDarwin then inputs.darwin-stable else inputs.nixos-stable;
  extra86 =
    pkgset:
    import pkgset {
      system = "x86_64-darwin";
      inherit config;
    };

  # Overlay to fix google-cloud-sdk components on Linux
  # The bundled Python in some components has _tkinter which needs tcl/tk
  # libraries for autoPatchelfHook to succeed
  gcloudOverlay = mfinal: mprev:
    let
      # Patch the components to include tcl/tk for autoPatchelfHook
      patchedComponents = mprev.callPackage
        "${inputs.nixpkgs-master}/pkgs/by-name/go/google-cloud-sdk/components.nix"
        {
          snapshotPath = "${inputs.nixpkgs-master}/pkgs/by-name/go/google-cloud-sdk/components.json";
          # Override stdenv to inject tcl/tk into buildInputs for all component derivations
          stdenv = mprev.stdenv // {
            mkDerivation =
              args:
              mprev.stdenv.mkDerivation (
                args
                // {
                  buildInputs = (args.buildInputs or [ ]) ++ [
                    mfinal.tcl
                    mfinal.tk
                  ];
                }
              );
          };
        };
      patchedWithExtraComponents = mprev.callPackage
        "${inputs.nixpkgs-master}/pkgs/by-name/go/google-cloud-sdk/withExtraComponents.nix"
        { components = patchedComponents; };
    in
    {
      google-cloud-sdk = mprev.google-cloud-sdk.overrideAttrs (oldAttrs: {
        passthru = oldAttrs.passthru // {
          components = patchedComponents;
          withExtraComponents = patchedWithExtraComponents;
        };
      });
    };
in
{
  master =
    if final.stdenv.isLinux then
      import inputs.nixpkgs-master {
        inherit system config;
        overlays = [ gcloudOverlay ];
      }
    else
      inputs.nixpkgs-master.legacyPackages.${system};
  stable = nixpkgs-stable.legacyPackages.${system};

  # put determinate nix in a separate package set so we can decide which
  # version to use depending on the machine.
  determinate = {
    nix = inputs.nix.packages.${system}.nix;
  };
}
// inputs.nixpkgs.lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
  x86 = (extra86 inputs.nixpkgs) // {
    master = extra86 inputs.nixpkgs-master;
    stable = extra86 nixpkgs-stable;
  };
}
