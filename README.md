# Systems management

This nix configuration provides unified machine management across Mac, NixOS
and Linux with nix/home-manager.

It is implemented using the flakes feature available from nix 2.8.

## Apply nix-darwin config

For example:

```
$ darwin-rebuild switch --flake .
```

(assuming the current hostname has an entry in `darwinConfigurations`)

## Apply raw home-manager config

For example:

```
$ nix profile install --profile $HOME/.nix-default-profile "nixpkgs#nixFlakes"
$ export PATH=~/.nix-default-profile/bin:$PATH
$ nix run ".#home-manager" --  switch --flake ".#glinux"
```
