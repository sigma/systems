{ pkgs, ... }:
{
  enable = true;
  nix-direnv.enable = true;
  stdlib = ''
    : ''${XDG_CACHE_HOME:=$HOME/.cache}
    declare -A direnv_layout_dirs
    direnv_layout_dir() {
      echo "''${direnv_layout_dirs[$PWD]:=$(
        local hash="$(${pkgs.coreutils}/bin/sha1sum - <<<"''${PWD}" | cut -c-7)"
        local path="''${PWD//[^a-zA-Z0-9]/-}"
        echo "''${XDG_CACHE_HOME}/direnv/layouts/''${hash}''${path}"
      )}"
    }
  '';

  config.global = {
    bash_path = "${pkgs.bash}/bin/bash";
    disable_stdin = true;
    strict_env = true;
    hide_env_diff = true;
  };
}
