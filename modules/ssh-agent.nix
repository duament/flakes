{ config, lib, pkgs, ... }:
with lib;
let
  keys = [ "canokey" "a4b" "ybk" ];
  user = config.users.users.rvfg.name;
in
{
  options = {
    presets.ssh-agent.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.ssh-agent.enable {
    sops.secrets = builtins.listToAttrs (map
      (key: {
        name = "ssh-key/id_${key}";
        value = {
          sopsFile = ../secrets/ssh-keys.yaml;
          mode = "0400";
          owner = user;
        };
      })
      keys);

    programs.ssh.startAgent = true;
    systemd.user.services.ssh-add-key = {
      wantedBy = [ "default.target" ];
      unitConfig.ConditionUser = user;
      after = [ "ssh-agent.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = map (key: "${pkgs.openssh}/bin/ssh-add ${config.sops.secrets."ssh-key/id_${key}".path}") keys;
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
  };
}
