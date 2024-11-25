{...}: {
  enable = true;

  fishNative = [
    # completion of files for checkout is broken
    "git"
    # carapace completion breaks when private recipes are enabled
    "just"
  ];
}
