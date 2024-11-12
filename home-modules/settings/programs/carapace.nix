{...}: {
  enable = true;

  fishNative = [
    # carapace completion breaks when private recipes are enabled
    "just"
  ];
}
