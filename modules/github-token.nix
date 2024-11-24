{
  config,
  lib,
  self,
  ...
}:
let
  enable =
    builtins.elem config.networking.hostName
      self.data.sops.secrets."secrets/github-token.yaml";
in
{
  config = lib.mkIf enable {

    sops = {
      secrets.github-token = {
        mode = "0444";
        sopsFile = ../secrets/github-token.yaml;
      };
      templates = {
        "nix-github-token.conf" = {
          mode = "0444";
          content = ''
            extra-access-tokens = github.com=${config.sops.placeholder.github-token}
          '';
        };
        "nvchecker-github-token.toml" = {
          mode = "0444";
          content = ''
            [keys]
            github = "${config.sops.placeholder.github-token}"
          '';
        };
      };
    };

    nix.extraOptions = ''
      !include ${config.sops.templates."nix-github-token.conf".path}
    '';

  };
}
