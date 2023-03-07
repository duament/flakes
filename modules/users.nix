{ config, lib, pkgs, self, ... }:
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

    users.users.root.passwordFile = config.sops.secrets.passwd.path;

    users.users.rvfg = {
      isNormalUser = true;
      passwordFile = config.sops.secrets.passwd.path;
      extraGroups = [ "systemd-journal" ];
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
