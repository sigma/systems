# Local LLM endpoints by API protocol.
#
# The module that provisions a local inference server (e.g.
# darwin-modules/apps/lm-studio.nix) publishes its endpoint here under the
# protocol it speaks; consumers (Zed edit predictions) look endpoints up by
# protocol and never name the server.
{ lib, ... }:
{
  options.programs.aiApis = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    example = {
      openai-compatible = "http://localhost:1234";
    };
    description = "API protocol → endpoint URL of the machine's local LLM server.";
  };
}
