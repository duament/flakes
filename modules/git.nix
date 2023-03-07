{ config, lib, pkgs, self, ... }:
with lib;
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
      openssh.authorizedKeys.keys = self.data.sshPub.authorizedKeys;
      createHome = true;
      home = "/var/lib/git";
      homeMode = "750";
      packages = [ pkgs.git ];
    };

    services.openssh.extraConfig = "AllowUsers git";
  };
}
