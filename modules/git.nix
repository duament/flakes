{ config, lib, pkgs, ... }:
with lib;
let
  sshPub = import ../lib/ssh-pubkeys.nix;
  authorizedKeys = with sshPub; [ ybk canokey a4b ed25519 ];
in
{
  options = {
    presets.git.enable = mkEnableOption "Git server";
  };

  config = mkIf config.presets.git.enable {
    users.groups.git = { };
    users.users.git = {
      isSystemUser = true;
      group = "git";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = authorizedKeys;
      createHome = true;
      home = "/var/lib/git";
      homeMode = "750";
      packages = [ pkgs.git ];
    };

    services.openssh.extraConfig = "AllowUsers git";
  };
}
