# Apply nix-darwin config

For example:

```
$ darwin-rebuild switch --flake .
```

(assuming the current hostname has an entry in `darwinConfigurations`)

# Apply raw home-manager config

For example:

```
$ nix run ".#home-manager" --  switch --flake ".#glinux"
```

