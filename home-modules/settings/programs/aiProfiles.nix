{
  config,
  lib,
  machine,
  ...
}:
let
  c = config.programs.aiCatalog;
in
{
  agents =
    [
      c.plans.claude-max
      c.plans.google-ai-pro
      c.plans.z-ai-coding
    ]
    ++ lib.optionals machine.features.firefly [
      c.plans.firefly-claude
      c.plans.firefly-opencode
    ];

  editPredictions = {
    model = c.localModels.gemma4-31b-coding;
    max_output_tokens = 64;
  };
}
