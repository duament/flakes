{
  config,
  lib,
  pkgs,
  self,
  ...
}:
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
            command = "/run/current-system/sw/bin/systemd-run ^((-E |--)[^ ]* )*(true|/nix/store/[^/ ]*/bin/switch-to-configuration (switch|boot))$";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    #security.sudo.extraConfig = ''
    #  Defaults passwd_timeout=0
    #'';

    # libpam_rssh
    security.pam.services.sudo.text = lib.mkDefault (
      lib.mkBefore ''
        auth sufficient ${pkgs.pam_rssh}/lib/libpam_rssh.so auth_key_file=/etc/ssh/authorized_keys.d/rvfg
      ''
    );
    security.sudo.extraConfig = ''
      Defaults env_keep+=SSH_AUTH_SOCK
    '';

  };
}
