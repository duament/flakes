{ config, lib, self, ... }:
let
  cfg = config.presets.users;
in
{
  options = {
    presets.users.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.passwd = {
      neededForUsers = true;
      sopsFile = ../secrets/passwd.yaml;
    };

    users.users.root.hashedPasswordFile = config.sops.secrets.passwd.path;

    users.groups.rvfg = {
      gid = 1000;
    };
    users.users.rvfg = {
      isNormalUser = true;
      uid = 1000;
      group = "rvfg";
      hashedPasswordFile = config.sops.secrets.passwd.path;
      extraGroups = [ "systemd-journal" "input" ];
      openssh.authorizedKeys.keys = self.data.sshPub.authorizedKeys;
    };

    users.groups.deploy = { };
    users.users.deploy = {
      isSystemUser = true;
      group = "deploy";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = self.data.sshPub.authorizedKeys;
    };

    security.sudo.extraRules = [
      {
        users = [ "rvfg" ];
        commands = [ "ALL" ];
      }
      {
        users = [ "deploy" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nix-env";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/nix/store/*/bin/switch-to-configuration";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    #security.sudo.extraConfig = ''
    #  Defaults passwd_timeout=0
    #'';
  };
}
