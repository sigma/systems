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
  agents = [
    c.plans.claude-max
    c.plans.google-ai-pro
    c.plans.z-ai-coding
  ]
  ++ lib.optionals machine.features.firefly [
    c.plans.firefly-claude
    c.plans.firefly-opencode
  ];

  # Edit predictions need a local backend; only configure them on hosts that
  # run one. Without this guard, hosts without `features.llm` would advertise
  # an endpoint nothing is listening on.
  editPredictions =
    if machine.features.llm or false then
      {
        model = c.localModels.gemma;
        max_output_tokens = 64;
      }
    else
      null;
}
