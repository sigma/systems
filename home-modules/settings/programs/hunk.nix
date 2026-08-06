{
  config,
  lib,
  machine,
  pkgs,
  ...
}:
{
  # hunk ships as a Bun single-file executable, and Bun's default x64 build
  # targets x86-64-v3 — it faults on `shlx` (BMI2) on pre-Haswell CPUs.
  # Upstream publishes no `-baseline` artifact, so there the binary SIGILLs on
  # *every* invocation. That is silent when it sits in a pager seat: the pager
  # dies and takes the output with it, so `git diff` and `jj log` just come
  # back blank. Stay off on those hosts and leave the seat to delta.
  enable = !machine.features.nehalem;

  pager = "${pkgs.less}/bin/less -RF";

  editor = lib.mkIf config.programs.neovim-ide.enable "${config.programs.nvf.finalPackage}/bin/nvim";

  settings = {
    transparent_background = true;
  };
}
