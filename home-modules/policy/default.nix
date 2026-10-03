# Policy modules, each gated internally on its machine feature.
{
  imports = [
    ./arbora.nix # machine.features.arbora
    ./devbox.nix # machine.features.devbox
    ./firefly.nix # machine.features.firefly
  ];
}
