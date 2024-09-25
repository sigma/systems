{
  lib,
  pkgs,
  machine,
  ...
}:
lib.optionalAttrs (machine.isWork) {
  # those files are handled by corp and will be reverted anyway, so
  # skip the warning about them being overwritten.
  environment.etc = {
    "shells".knownSha256Hashes = [
      # default MacOS content. This is safe to override
      "9d5aa72f807091b481820d12e693093293ba33c73854909ad7b0fb192c2db193"
    ];
    "zshrc".knownSha256Hashes = [
      "7055352423251faa46af6bb3b1754b0119558f5460c4b49d27189a9cac794bc3"
      "0c65e335c154a6b4a88f635c7b2aee8c6f49bd48ee522fd3685f75e2686b6af3"
    ];
    # leave bashrc alone, I don't use bash
    "bashrc".enable = false;
  };

  environment.systemPackages = [
    pkgs.gitGoogle
  ];
}
