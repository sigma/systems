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
      config,
      ...
    }:
    let
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

      # Secrets directory location
      secretsDir =
        if isDarwin then "/run/secrets"
        else if builtins.pathExists "/etc/nixos" then "/run/secrets"
        else "$HOME/.config/sops-nix/secrets";
    in
    {
      pre-commit.settings.hooks = {
        markdownlint.enable = true;
        treefmt.enable = true;

        treefmt.settings.formatters = [
          pkgs.nixfmt-rfc-style
          pkgs.mdformat
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
            command = ''
              echo "# Generated SOPS configuration"
              echo "# To update .sops.yaml: sops-config > .sops.yaml"
              echo ""
              cat ${sopsConfigFile}
            '';
          }
          {
            name = "sops-edit";
            category = "secrets";
            help = "Edit encrypted secrets file (creates if missing)";
            command = ''
              FILE="''${1:-secrets/secrets.yaml}"
              if [[ ! -f "$FILE" ]]; then
                echo "Creating new secrets file: $FILE"
                mkdir -p "$(dirname "$FILE")"
              fi
              # Use SSH key for age decryption if no age key file is set
              if [[ -z "''${SOPS_AGE_KEY_FILE:-}" && -z "''${SOPS_AGE_KEY:-}" ]]; then
                SSH_KEY="''${SOPS_AGE_SSH_PRIVATE_KEY:-$HOME/.ssh/id_ed25519}"
                if [[ -f "$SSH_KEY" ]]; then
                  export SOPS_AGE_KEY=$(${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$SSH_KEY")
                fi
              fi
              ${pkgs.sops}/bin/sops --config ${sopsConfigFile} "$FILE"
            '';
          }
          {
            name = "sops-key";
            category = "secrets";
            help = "Show age public key (-t ssh|yubikey, default: ssh)";
            command = ''
              TYPE="ssh"
              while getopts "t:" opt; do
                case $opt in
                  t) TYPE="$OPTARG" ;;
                  *) echo "Usage: sops-key [-t ssh|yubikey] [path/to/ssh/key]"; exit 1 ;;
                esac
              done
              shift $((OPTIND-1))

              case "$TYPE" in
                ssh)
                  SSH_KEY="''${1:-$HOME/.ssh/id_ed25519}"
                  if [[ ! -f "$SSH_KEY" ]]; then
                    echo "SSH key not found: $SSH_KEY"
                    echo "Usage: sops-key [-t ssh] [path/to/ssh/key]"
                    exit 1
                  fi
                  echo "# Age public key for: $SSH_KEY"
                  ${pkgs.ssh-to-age}/bin/ssh-to-age -i "$SSH_KEY.pub" 2>/dev/null || \
                  ${pkgs.ssh-to-age}/bin/ssh-to-age < "$SSH_KEY.pub"
                  ;;
                yubikey)
                  echo "# Age public key from YubiKey"
                  ${pkgs.age-plugin-yubikey}/bin/age-plugin-yubikey --identity
                  ;;
                *)
                  echo "Unknown key type: $TYPE"
                  echo "Usage: sops-key [-t ssh|yubikey]"
                  exit 1
                  ;;
              esac
            '';
          }
          {
            name = "bootstrap-github";
            category = "secrets";
            help = "Upload machine SSH key to GitHub using decrypted PAT (requires sudo)";
            command = ''
              PAT_FILE="${secretsDir}/github-key-uploader-pat"
              if [[ ! -f "$PAT_FILE" ]]; then
                echo "GitHub PAT not found at: $PAT_FILE"
                echo "Run system-install or home-install first to decrypt secrets"
                exit 1
              fi

              SSH_KEY="''${1:-$HOME/.ssh/id_ed25519.pub}"
              if [[ ! -f "$SSH_KEY" ]]; then
                echo "SSH public key not found: $SSH_KEY"
                exit 1
              fi

              echo "Authenticating with GitHub..."
              ${pkgs.gh}/bin/gh auth login --with-token < "$PAT_FILE"

              echo "Uploading SSH key: $SSH_KEY"
              ${pkgs.gh}/bin/gh ssh-key add "$SSH_KEY" --title "$(hostname -s)-$(date +%Y%m%d)"

              echo "Done! You can now use: gh auth setup-git"
            '';
          }
        ];
      };
    };
}
