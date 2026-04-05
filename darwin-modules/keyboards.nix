# Shared keyboard definitions for Karabiner policy modules.
# Centralizes vendor IDs and product IDs so they aren't duplicated
# across laptop.nix, desktop.nix, etc.
{
  keychron = pid: {
    vendorId = 13364;
    productId = pid;
  };

  massdrop = pid: {
    vendorId = 1240;
    productId = pid;
  };
}
