# Systems management

This nix configuration provides unified machine management across Mac, NixOS
and Linux with nix/home-manager.

It is implemented using the flakes feature available from nix 2.8.

## Apply nix-darwin config

For example:

```shell
darwin-rebuild switch --flake .
```

(assuming the current hostname has an entry in `darwinConfigurations`)

## Apply raw home-manager config

For example:

```shell
nix profile install --profile $HOME/.nix-default-profile "nixpkgs#nixFlakes"
export PATH=~/.nix-default-profile/bin:$PATH
nix run ".#home-manager" --  switch --flake ".#glinux"
```

## Speed run

With just a recent `nix` and `direnv` installed, a set of convenience helpers
become available. Among them `system-install`, which *should* handle the
end-to-end install for a new system, as long as its hostname is registered.
