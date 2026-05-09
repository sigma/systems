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

      # Devbox tools (key generation; install/rebuild are inline below)
      devboxTools = pkgs.callPackage ../overlays/pkg/local/devbox-tools.nix {
        inherit sopsConfigFile;
      };

      # Lifecycle scripts (bootstrap/rebuild/start/stop/remove) come from
      # firefly-engineering/devbox. Hooks here weave in this repo's
      # specifics: per-host SSH keys live in sops, the parent's pubkey
      # comes from ~/.ssh/id_ed25519.pub, and rebuilds re-key sops first.
      devboxScripts = inputs.devbox.lib.mkScripts {
        inherit pkgs;
        flakeRef = ".";

        privateKeyHook = ''
          KEY_TMPDIR=$(mktemp -d)
          # shellcheck disable=SC2064
          trap "rm -rf $KEY_TMPDIR" EXIT
          chmod 0700 "$KEY_TMPDIR"

          # Make the parent's SSH key available to sops as an age identity
          if [ -z "''${SOPS_AGE_KEY_FILE:-}" ] && [ -z "''${SOPS_AGE_KEY:-}" ]; then
            SSH_AGE_SRC="''${SOPS_AGE_SSH_PRIVATE_KEY:-$HOME/.ssh/id_ed25519}"
            if [ -f "$SSH_AGE_SRC" ]; then
              SOPS_AGE_KEY=$(${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$SSH_AGE_SRC")
              export SOPS_AGE_KEY
            fi
          fi

          # Decrypt the devbox SSH user key from sops if present.
          SOPS_ERR="$KEY_TMPDIR/sops.err"
          if ${pkgs.sops}/bin/sops -d --extract "[\"devbox-keys\"][\"$HOST\"]" \
               "secrets/secrets.yaml" > "$KEY_TMPDIR/id_ed25519" 2>"$SOPS_ERR"; then
            chmod 0600 "$KEY_TMPDIR/id_ed25519"
            export DEVBOX_SSH_KEY="$KEY_TMPDIR/id_ed25519"
            echo "==> Loaded SSH key for $HOST from sops"
          else
            echo "==> Could not decrypt devbox-keys/$HOST from sops; installer will skip key injection"
            echo "    sops error:"
            ${pkgs.gnused}/bin/sed 's/^/      /' "$SOPS_ERR"
            echo "    If the entry is missing, run: devbox-keygen $HOST"
          fi
        '';

        parentPubKeyHook = ''
          PARENT_PUBKEY="$HOME/.ssh/id_ed25519.pub"
          if [ -f "$PARENT_PUBKEY" ]; then
            export DEVBOX_PARENT_PUBKEY="$PARENT_PUBKEY"
          else
            echo "==> No $PARENT_PUBKEY found; SSH from this host into $HOST will require manual setup"
          fi
        '';

        preRebuildHook = ''
          # Set up the parent's age identity so sops can decrypt and re-key.
          if [ -z "''${SOPS_AGE_KEY_FILE:-}" ] && [ -z "''${SOPS_AGE_KEY:-}" ]; then
            SSH_AGE_SRC="''${SOPS_AGE_SSH_PRIVATE_KEY:-$HOME/.ssh/id_ed25519}"
            if [ -f "$SSH_AGE_SRC" ]; then
              SOPS_AGE_KEY=$(${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$SSH_AGE_SRC")
              export SOPS_AGE_KEY
            fi
          fi

          # Re-key sops with the in-store config (no .sops.yaml on disk).
          # Idempotent: no-op when secrets.yaml's recipients already match
          # modules/secrets.nix. Catches the common case of a fresh
          # devbox-keygen recipient that wasn't yet propagated.
          echo "==> Refreshing sops recipients..."
          ${pkgs.sops}/bin/sops --config ${sopsConfigFile} \
            updatekeys -y "secrets/secrets.yaml"
        '';
      };
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
            name = "devbox-keygen";
            category = "devbox";
            help = "Generate an SSH key for a devbox and stash it in sops (usage: devbox-keygen <hostname>)";
            command = ''exec ${devboxTools.devbox-keygen}/bin/devbox-keygen "$@"'';
          }
          {
            name = "devbox-bootstrap";
            category = "devbox";
            help = "Create a devbox VM and bootstrap a minimal NixOS (run devbox-rebuild after) (usage: devbox-bootstrap <hostname>)";
            command = ''exec ${devboxScripts.devbox-bootstrap}/bin/devbox-bootstrap "$@"'';
          }
          {
            name = "devbox-rebuild";
            category = "devbox";
            help = "Rebuild a running devbox via SSH (usage: devbox-rebuild <hostname>)";
            command = ''exec ${devboxScripts.devbox-rebuild}/bin/devbox-rebuild "$@"'';
          }
          {
            name = "devbox-start";
            category = "devbox";
            help = "Start a devbox VM headless in the background (usage: devbox-start <hostname>)";
            command = ''exec ${devboxScripts.devbox-start}/bin/devbox-start "$@"'';
          }
          {
            name = "devbox-stop";
            category = "devbox";
            help = "Stop a running devbox VM (usage: devbox-stop <hostname>)";
            command = ''exec ${devboxScripts.devbox-stop}/bin/devbox-stop "$@"'';
          }
          {
            name = "devbox-remove";
            category = "devbox";
            help = "Stop and delete a devbox VM, plus its local logs (usage: devbox-remove <hostname>)";
            command = ''exec ${devboxScripts.devbox-remove}/bin/devbox-remove "$@"'';
          }
        ];
      };
    };
}
