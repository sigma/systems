{ config, ... }:
{
  inherit (config.features.dev) enable;
  enableGitIntegration = true;

  options = {
    navigate = true;
    hyperlinks = true;

    interactive = {
      "keep-plus-minus-markers" = false;
    };
  };
}
