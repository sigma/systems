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
            help = "Create a devbox VM and bootstrap a minimal NixOS (run devbox-rebuild after) (usage: devbox-bootstrap <hostname> [disk-gb])";
            command = ''
              ${findNix}
              if [ -z "$1" ]; then
                echo "Usage: devbox-bootstrap <hostname> [disk-gb]"
                echo "Example: devbox-bootstrap ash-devbox 50"
                exit 1
              fi

              if ! command -v tart &>/dev/null; then
                echo "Error: tart not found. Install with: brew install cirruslabs/cli/tart"
                exit 1
              fi

              HOST="$1"
              DISK_GB="''${2:-50}"
              FLAKE_DIR="$(pwd)"

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

              # Decrypt the devbox SSH user key from sops if present
              SOPS_ERR="$KEY_TMPDIR/sops.err"
              if ${pkgs.sops}/bin/sops -d --extract "[\"devbox-keys\"][\"$HOST\"]" \
                   "$FLAKE_DIR/secrets/secrets.yaml" > "$KEY_TMPDIR/id_ed25519" 2>"$SOPS_ERR"; then
                chmod 0600 "$KEY_TMPDIR/id_ed25519"
                export DEVBOX_SSH_KEY="$KEY_TMPDIR/id_ed25519"
                echo "==> Loaded SSH key for $HOST from sops"
              else
                echo "==> Could not decrypt devbox-keys/$HOST from sops; installer will skip key injection"
                echo "    sops error:"
                ${pkgs.gnused}/bin/sed 's/^/      /' "$SOPS_ERR"
                echo "    If the entry is missing, run: devbox-keygen $HOST"
              fi

              # Pass the parent's SSH public key so the installer can authorize it
              PARENT_PUBKEY="$HOME/.ssh/id_ed25519.pub"
              if [ -f "$PARENT_PUBKEY" ]; then
                cp "$PARENT_PUBKEY" "$KEY_TMPDIR/parent.pub"
                export DEVBOX_PARENT_PUBKEY="$KEY_TMPDIR/parent.pub"
              else
                echo "==> No $PARENT_PUBKEY found; SSH from this host into $HOST will require manual setup"
              fi

              # Step 1: Build the auto-install ISO (impure: reads DEVBOX_* env vars)
              echo "==> Building installer ISO for $HOST..."
              $NIX_BIN ${nixFlags} build --impure \
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
              echo "==> Bootstrap complete! The VM has a minimal NixOS — no home-manager,"
              echo "    no flake config yet. Next:"
              echo ""
              echo "      devbox-start $HOST              # if not already running"
              echo "      devbox-rebuild $HOST            # apply the full config"
              echo "      ssh $HOST sudo tailscale up    # register on the tailnet (manual"
              echo "                                       so we don't bake an expiring authkey"
              echo "                                       into sops). Use a key from"
              echo "                                       https://login.tailscale.com/admin/settings/keys"
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

              if ! command -v tart &>/dev/null; then
                echo "Error: tart not found. Install with: brew install cirruslabs/cli/tart"
                exit 1
              fi

              HOST="$1"
              FLAKE_DIR="$(pwd)"

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
                updatekeys -y "$FLAKE_DIR/secrets/secrets.yaml"

              # Resolve via tart so first rebuild works before tailscale comes up.
              # Bypasses the SSH config alias (which points at *.ts.net) and the
              # known_hosts entry (the VM's host key changes across rebuilds).
              IP=$(tart ip "$HOST" 2>/dev/null || true)
              if [ -z "$IP" ]; then
                echo "Error: tart ip returned no address for $HOST. Is it running?"
                echo "       devbox-start $HOST"
                exit 1
              fi

              # Connect to the raw IP, not the SSH config alias. The alias
              # carries RequestTTY=force, a tailscale Hostname, and a custom
              # ControlPath — which interfere with first-rebuild auth before
              # the devbox is on the tailnet. Using $IP picks up only the *
              # block, mirroring `ssh $IP` which authenticates with the agent.
              SSH_OPTS=(
                -o "StrictHostKeyChecking=accept-new"
                -o "UserKnownHostsFile=/dev/null"
                -o "LogLevel=ERROR"
              )

              # -T keeps rsync's channel clean of pty escape interpretation.
              RSYNC_SSH_OPTS=(-T "''${SSH_OPTS[@]}")

              echo "==> Copying flake to $HOST ($IP)..."
              rsync -az --rsh "ssh ''${RSYNC_SSH_OPTS[*]}" --exclude='.git' --exclude='result' \
                "$FLAKE_DIR/" "$IP:/tmp/nix-config/"

              echo "==> Running nixos-rebuild switch on $HOST..."
              ssh "''${SSH_OPTS[@]}" -t "$IP" "sudo nixos-rebuild switch --flake /tmp/nix-config#$HOST"

              echo "==> Done! $HOST has been rebuilt."
              echo "    If $HOST isn't on your tailnet yet, register it manually:"
              echo "      ssh $HOST sudo tailscale up"
            '';
          }
          {
            name = "devbox-start";
            category = "devbox";
            help = "Start a devbox VM headless in the background (usage: devbox-start <hostname>)";
            command = ''
              ${findNix}
              if [ -z "$1" ]; then
                echo "Usage: devbox-start <hostname>"
                exit 1
              fi

              if ! command -v tart &>/dev/null; then
                echo "Error: tart not found. Install with: brew install cirruslabs/cli/tart"
                exit 1
              fi

              HOST="$1"

              if tart list --quiet 2>/dev/null | grep -qE "^$HOST(\s|$)"; then
                STATE=$(tart list --format json 2>/dev/null \
                  | ${pkgs.jq}/bin/jq -r ".[] | select(.Name == \"$HOST\") | .State")
                if [ "$STATE" = "running" ]; then
                  echo "==> $HOST is already running"
                  exit 0
                fi
              else
                echo "Error: tart VM '$HOST' not found. Run devbox-bootstrap $HOST first."
                exit 1
              fi

              # --nested is a tart run flag and must be passed each invocation
              NESTED=$($NIX_BIN ${nixFlags} eval --raw \
                ".#nixosConfigurations.$HOST.config.system.build.devboxNested")
              NESTED_FLAG=""
              if [ "$NESTED" = "true" ]; then
                NESTED_FLAG="--nested"
              fi

              LOG_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/devbox"
              mkdir -p "$LOG_DIR"
              LOG="$LOG_DIR/$HOST.log"

              echo "==> Starting $HOST headless (log: $LOG)..."
              nohup tart run $NESTED_FLAG --no-graphics "$HOST" \
                >> "$LOG" 2>&1 < /dev/null &
              disown

              # Wait briefly for tart to register the VM as running
              for _ in 1 2 3 4 5; do
                sleep 1
                STATE=$(tart list --format json 2>/dev/null \
                  | ${pkgs.jq}/bin/jq -r ".[] | select(.Name == \"$HOST\") | .State")
                if [ "$STATE" = "running" ]; then
                  IP=$(tart ip "$HOST" 2>/dev/null || true)
                  echo "==> $HOST is running (ip: ''${IP:-pending})"
                  exit 0
                fi
              done

              echo "==> $HOST start initiated; check $LOG if it doesn't come up"
            '';
          }
          {
            name = "devbox-stop";
            category = "devbox";
            help = "Stop a running devbox VM (usage: devbox-stop <hostname>)";
            command = ''
              if [ -z "$1" ]; then
                echo "Usage: devbox-stop <hostname>"
                exit 1
              fi

              if ! command -v tart &>/dev/null; then
                echo "Error: tart not found. Install with: brew install cirruslabs/cli/tart"
                exit 1
              fi

              HOST="$1"

              STATE=$(tart list --format json 2>/dev/null \
                | ${pkgs.jq}/bin/jq -r ".[] | select(.Name == \"$HOST\") | .State")
              if [ -z "$STATE" ] || [ "$STATE" = "null" ]; then
                echo "Error: tart VM '$HOST' not found"
                exit 1
              fi
              if [ "$STATE" != "running" ]; then
                echo "==> $HOST is not running (state: $STATE)"
                exit 0
              fi

              echo "==> Stopping $HOST..."
              tart stop "$HOST"
              echo "==> $HOST stopped"
            '';
          }
          {
            name = "devbox-remove";
            category = "devbox";
            help = "Stop and delete a devbox VM, plus its local logs (usage: devbox-remove <hostname>)";
            command = ''
              if [ -z "$1" ]; then
                echo "Usage: devbox-remove <hostname>"
                exit 1
              fi

              if ! command -v tart &>/dev/null; then
                echo "Error: tart not found. Install with: brew install cirruslabs/cli/tart"
                exit 1
              fi

              HOST="$1"

              STATE=$(tart list --format json 2>/dev/null \
                | ${pkgs.jq}/bin/jq -r ".[] | select(.Name == \"$HOST\") | .State")
              if [ -z "$STATE" ] || [ "$STATE" = "null" ]; then
                echo "==> tart VM '$HOST' not found; nothing to do"
                exit 0
              fi

              if [ "$STATE" = "running" ]; then
                echo "==> Stopping $HOST..."
                tart stop "$HOST"
              fi

              echo "==> Deleting tart VM '$HOST'..."
              tart delete "$HOST"

              LOG="''${XDG_STATE_HOME:-$HOME/.local/state}/devbox/$HOST.log"
              if [ -f "$LOG" ]; then
                rm -f "$LOG"
                echo "==> Removed $LOG"
              fi

              echo "==> $HOST removed."
              echo "    Note: sops entry devbox-keys/$HOST and the age recipient in"
              echo "    modules/secrets.nix were left in place. Drop them manually if"
              echo "    you don't plan to reuse them with devbox-bootstrap $HOST."
            '';
          }
        ];
      };
    };
}
