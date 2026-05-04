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

        sops-keys = {
          enable = secretsCfg.enable;
          name = "SOPS age keys in sync";
          description = "Check that .sops.yaml contains the same age keys as modules/secrets.nix";
          files = "\\.(nix|yaml)$";
          entry = "${pkgs.bash}/bin/bash -c '${
            let
              nixKeys = builtins.map (k: k.publicKey) secretsCfg.ageKeys;
              checkCommands = builtins.map (key: ''
                if ! ${pkgs.gnugrep}/bin/grep -qF "${key}" .sops.yaml 2>/dev/null; then
                  echo "ERROR: age key missing from .sops.yaml: ${key}"
                  echo "Run: sops-config > .sops.yaml && sops updatekeys secrets/secrets.yaml"
                  exit 1
                fi
              '') nixKeys;
            in
              ''
                if [ ! -f .sops.yaml ]; then
                  echo "WARNING: .sops.yaml does not exist. Run: sops-config > .sops.yaml"
                  exit 1
                fi
              '' + builtins.concatStringsSep "" checkCommands
          }'";
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
          nixd # for VSCode integration.
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
            '';
          }
          {
            name = "system-install";
            category = "system";
            help = "Build and activate full system configuration";
            command = ''
              ${findNix}
              ${systemSetup}
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
            name = "devbox-install";
            category = "devbox";
            help = "Create a devbox VM and bootstrap NixOS (usage: devbox-install <hostname> [disk-gb])";
            command = ''
              ${findNix}
              if [ -z "$1" ]; then
                echo "Usage: devbox-install <hostname> [disk-gb]"
                echo "Example: devbox-install ash-devbox 50"
                exit 1
              fi

              if ! command -v tart &>/dev/null; then
                echo "Error: tart not found. Install with: brew install cirruslabs/cli/tart"
                exit 1
              fi

              HOST="$1"
              DISK_GB="''${2:-50}"
              FLAKE_DIR="$(pwd)"

              # Step 1: Build the auto-install ISO
              echo "==> Building installer ISO for $HOST..."
              $NIX_BIN ${nixFlags} build \
                ".#nixosConfigurations.$HOST.config.system.build.devboxInstaller" \
                -o "./$HOST-installer"

              ISO=$(find -L "./$HOST-installer" -name '*.iso' | head -1)
              if [ -z "$ISO" ]; then
                echo "Error: No ISO found in ./$HOST-installer/"
                exit 1
              fi

              # Query whether nested virt is requested for this host.
              # Note: tart's --nested is a `tart run` flag (not `tart create`).
              NESTED=$($NIX_BIN ${nixFlags} eval --raw \
                ".#nixosConfigurations.$HOST.config.system.build.devboxNested")
              NESTED_FLAG=""
              if [ "$NESTED" = "true" ]; then
                NESTED_FLAG="--nested"
                echo "==> Nested virtualization enabled for $HOST"
              fi

              # Step 2: Create tart VM
              echo "==> Creating Tart VM '$HOST' (''${DISK_GB}GB disk)..."
              tart delete "$HOST" 2>/dev/null || true
              tart create --linux "$HOST" --disk-size "$DISK_GB"

              # Step 3: Boot ISO (auto-installs and powers off)
              echo "==> Booting installer ISO (a VM window will open)..."
              echo "    The VM will auto-partition, install NixOS, and shut down."
              tart run $NESTED_FLAG --disk "$ISO:ro" "$HOST" || true

              # Step 4: Clean up ISO
              rm -rf "./$HOST-installer"

              echo ""
              echo "==> Bootstrap install complete!"
              echo ""
              echo "Next steps:"
              echo "  1. Start the VM:  tart run $NESTED_FLAG $HOST"
              echo "  2. SSH in:        ssh $HOST"
              echo "  3. Clone config:  git clone <your-config-repo>"
              echo "  4. Rebuild:       sudo nixos-rebuild switch --flake .#$HOST"
              echo ""
              echo "Or run: devbox-rebuild $HOST"
            '';
          }
          {
            name = "devbox-rebuild";
            category = "devbox";
            help = "Rebuild a running devbox via SSH (usage: devbox-rebuild <hostname>)";
            command = ''
              ${findNix}
              if [ -z "$1" ]; then
                echo "Usage: devbox-rebuild <hostname>"
                exit 1
              fi

              HOST="$1"
              FLAKE_DIR="$(pwd)"

              echo "==> Copying flake to $HOST..."
              rsync -az --exclude='.git' --exclude='result' \
                "$FLAKE_DIR/" "$HOST:/tmp/nix-config/"

              echo "==> Running nixos-rebuild switch on $HOST..."
              ssh -t "$HOST" "sudo nixos-rebuild switch --flake /tmp/nix-config#$HOST"

              echo "==> Done! $HOST has been rebuilt."
            '';
          }
        ];
      };
    };
}
