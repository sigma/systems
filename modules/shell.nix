{ inputs, config, ... }:
let
  secretsCfg = config.nebula.secrets;
in
{
  imports = [
    inputs.devshell.flakeModule
    inputs.pre-commit-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
    inputs.flake-root.flakeModule
  ];

  perSystem =
    {
      pkgs,
      system,
      config,
      ...
    }:
    let
      masterPkgs = inputs.nixpkgs-master.legacyPackages.${system};
      isDarwin = pkgs.stdenvNoCC.isDarwin;
      nixFlags = "--extra-experimental-features 'nix-command flakes'";

      systemSetup =
        if isDarwin then
          ''
            set -e
            echo >&2 "Installing Nix-Darwin..."
            # setup /run directory for darwin system installations
            if ! test -L /run; then
              if ! grep -q '^run\b' /etc/synthetic.conf 2>/dev/null; then
                echo "setting up /etc/synthetic.conf..."
                echo -e "run\tprivate/var/run" | sudo tee -a /etc/synthetic.conf >/dev/null
                /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B 2>/dev/null || true
                /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t 2>/dev/null || true
              fi
              if ! test -L /run; then
                  echo "setting up /run..."
                  sudo ln -sfn private/var/run /run
              fi
            fi
          ''
        else
          "";

      findNix = ''
        NIX_BIN=${pkgs.nix}/bin/nix
        if test -x /usr/local/bin/determinate-nixd; then
          NIX_BIN=/nix/var/nix/profiles/default/bin/nix
        fi
      '';

      systemBootstrap = "";

      systemBuild =
        if isDarwin then
          ''
            sudo $NIX_BIN ${nixFlags} build ".#darwinConfigurations.`hostname -s`.system"
          ''
        else
          ''
            if test -d /etc/nixos; then
              $NIX_BIN ${nixFlags} run ".#nixos-rebuild" -- build --flake ".#`hostname -s`"
            else
              $NIX_BIN ${nixFlags} run ".#home-manager" --  build --flake ".#`hostname -s`"
            fi
          '';

      systemActivate =
        if isDarwin then
          ''
            sudo $NIX_BIN ${nixFlags} run ".#darwin-rebuild" -- switch --flake ".#`hostname -s`"
          ''
        else
          ''
            if test -d /etc/nixos; then
              sudo $NIX_BIN ${nixFlags} run ".#nixos-rebuild" -- switch --flake ".#`hostname -s`"
            else
              $NIX_BIN ${nixFlags} run ".#home-manager" --  switch --flake ".#`hostname -s`"
            fi
          '';

      # Home-manager only activation (for darwin/nixos, activates just the home-manager part)
      homeBuild = ''
        $NIX_BIN ${nixFlags} build ".#homeConfigurations.`hostname -s`-$USER.activationPackage"
      '';

      homeActivate = ''
        $NIX_BIN ${nixFlags} run ".#home-manager" -- switch --flake ".#`hostname -s`-$USER"
      '';

      # SOPS configuration file generated from Nix
      sopsConfigFile = pkgs.writeText "sops.yaml" (
        if secretsCfg.enable then secretsCfg._sopsConfigText else "# Secrets not enabled"
      );

      # SOPS tools package
      sopsTools = pkgs.callPackage ../overlays/pkg/local/sops-tools.nix {
        inherit sopsConfigFile;
      };

      # Bootstrap tools packages (auto-detect secrets directory at runtime)
      bootstrapGithub = pkgs.callPackage ../overlays/pkg/local/bootstrap-github.nix { };
      bootstrapCachix = pkgs.callPackage ../overlays/pkg/local/bootstrap-cachix.nix { };
    in
    {
      pre-commit.settings.hooks = {
        markdownlint.enable = true;
        treefmt.enable = true;

        treefmt.settings.formatters = [
          pkgs.nixfmt
          masterPkgs.mdformat
          pkgs.beautysh
        ];

        flake-lock = {
          enable = true;
          name = "Unique flake inputs";
          description = "Check that all inputs are at a single version";
          files = "^flake\\.lock$";
          entry = "${pkgs.bash}/bin/bash -c '! ${pkgs.ripgrep}/bin/rg _\\\\d flake.lock'";
          pass_filenames = false;
        };
      };

      treefmt.config = {
        inherit (config.flake-root) projectRootFile;
        package = pkgs.treefmt;
        # formatters
        programs.nixfmt.enable = true;
        programs.mdformat.enable = true;
        programs.mdformat.package = masterPkgs.mdformat;
        programs.beautysh.enable = true;
      };

      devshells.default = {
        devshell = {
          name = "system-shell";
          # automatically enable pre-commit hooks in that shell
          startup.pre-commit.text = config.pre-commit.installationScript;
        };

        packages = with pkgs; [
          nil # for VSCode integration.
          age # for secrets encryption
          age-plugin-yubikey # for YubiKey-based age encryption
          sops # for secrets management
          ssh-to-age # for converting SSH keys to age
        ];

        commands = [
          {
            name = "system-bootstrap";
            category = "system";
            help = "Initial system setup (run once on new machines)";
            command = ''
              ${findNix}
              ${systemBootstrap}
            '';
          }
          {
            name = "system-install";
            category = "system";
            help = "Build and activate full system configuration";
            command = ''
              ${findNix}
              ${systemSetup}
              ${systemBootstrap}
              ${systemBuild}
              ${systemActivate}
            '';
          }
          {
            name = "system-test";
            category = "system";
            help = "Build system configuration (without activating)";
            command = ''
              ${findNix}
              ${systemBuild}
            '';
          }
          {
            name = "home-install";
            category = "home";
            help = "Activate home-manager configuration (without full system rebuild)";
            command = ''
              ${findNix}
              ${homeBuild}
              ${homeActivate}
            '';
          }
          {
            name = "home-test";
            category = "home";
            help = "Build home-manager configuration (without activating)";
            command = ''
              ${findNix}
              ${homeBuild}
            '';
          }
          {
            name = "sops-config";
            category = "secrets";
            help = "Show SOPS configuration (generated from Nix)";
            command = ''exec ${sopsTools.sops-config}/bin/sops-config "$@"'';
          }
          {
            name = "sops-edit";
            category = "secrets";
            help = "Edit encrypted secrets file (creates if missing)";
            command = ''exec ${sopsTools.sops-edit}/bin/sops-edit "$@"'';
          }
          {
            name = "sops-key";
            category = "secrets";
            help = "Show age public key (-t ssh|yubikey, default: ssh)";
            command = ''exec ${sopsTools.sops-key}/bin/sops-key "$@"'';
          }
          {
            name = "bootstrap-github";
            category = "bootstrap";
            help = "Upload machine SSH key to GitHub using decrypted PAT (requires sudo)";
            command = ''exec ${bootstrapGithub}/bin/bootstrap-github "$@"'';
          }
          {
            name = "bootstrap-cachix";
            category = "bootstrap";
            help = "Configure cachix authentication using decrypted tokens";
            command = ''exec ${bootstrapCachix}/bin/bootstrap-cachix "$@"'';
          }
          {
            name = "vm-generate";
            category = "vm";
            help = "Generate a VMware image for a NixOS host (usage: vm-generate <hostname> [output-dir])";
            command = ''
              ${findNix}
              if [ -z "$1" ]; then
                echo "Usage: vm-generate <hostname> [output-dir]"
                echo "Example: vm-generate spectre-devbox ./vm-images"
                exit 1
              fi
              HOST="$1"
              OUTPUT_DIR="''${2:-.}"
              OUTPUT_PATH="$OUTPUT_DIR/$HOST-vmware"

              echo "Generating VMware image for $HOST..."
              # Build directly from nixosConfigurations to use our patched pkgs
              $NIX_BIN ${nixFlags} build \
                ".#nixosConfigurations.$HOST.config.system.build.vmwareImage" \
                -o "$OUTPUT_PATH"

              echo "Image generated at: $OUTPUT_PATH"
            '';
          }
        ];
      };
    };
}
