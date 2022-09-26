{ config, pkgs, ... }:
let
  keys = [ "canokey" "a4b" ];
  user = config.users.users.rvfg.name;
in {
  sops.secrets = builtins.listToAttrs (map (key: {
    name = "ssh-key/id_${key}";
    value = {
      sopsFile = ./secrets.yaml;
      mode = "0400";
      owner = user;
    };
  }) keys);

  programs.ssh.startAgent = true;
  systemd.user.services.ssh-add-key = {
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = user;
    after = [ "ssh-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = map (key: "${pkgs.openssh}/bin/ssh-add ${config.sops.secrets."ssh-key/id_${key}".path}") keys;
    };
  };
}
