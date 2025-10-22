{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.presets.users;
  hashedPasswordFile =
    if cfg.hashedPasswordFile == "" then config.sops.secrets.passwd.path else cfg.hashedPasswordFile;
in
{
  options = {
    presets.users = {
      enable = lib.mkEnableOption "" // {
        default = true;
      };

      sudoKeys = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
      };

      hashedPasswordFile = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    presets.users.sudoKeys = lib.mkOrder 1200 self.data.sshPub.securityKeys;

    sops.secrets = lib.mkIf (cfg.hashedPasswordFile == "") {
      passwd = {
        neededForUsers = true;
        sopsFile = ../secrets/passwd.yaml;
      };
    };

    users.users.root.hashedPasswordFile = hashedPasswordFile;

    users.groups.rvfg = {
      gid = 1000;
    };
    users.users.rvfg = {
      isNormalUser = true;
      uid = 1000;
      group = "rvfg";
      hashedPasswordFile = hashedPasswordFile;
      extraGroups = [
        "systemd-journal"
        "input"
      ];
      openssh.authorizedKeys.keys = self.data.sshPub.authorizedKeys;
    };

    users.groups.deploy = { };
    users.users.deploy = {
      isSystemUser = true;
      group = "deploy";
      shell = pkgs.bashInteractive;
      openssh.authorizedKeys.keys = self.data.sshPub.authorizedKeys ++ [
        self.data.sshPub.github-action-deploy
      ];
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
            command = "^/nix/store/[^/ ]*/bin/switch-to-configuration$";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemd-run ^(-E [^ ]+ )*(-- )?(true|/nix/store/[^/ ]+/bin/switch-to-configuration (switch|boot))$";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/env ^([^= ]+=[^ ]* )*systemd-run (-E [^ ]+ |--[^ ]+ )*(-- )?(true|/nix/store/[^/ ]+/bin/switch-to-configuration (switch|boot))$";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    #security.sudo.extraConfig = ''
    #  Defaults passwd_timeout=0
    #'';

    # libpam_rssh
    security.pam.rssh = {
      enable = true;
      settings.auth_key_file = "/etc/ssh/pam_rssh_keys.d/$ruser";
    };
    security.pam.services.sudo.rssh = true;
    environment.etc."ssh/pam_rssh_keys.d/rvfg".text = lib.concatLines cfg.sudoKeys;

  };
}
