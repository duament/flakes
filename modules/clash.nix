{
  config,
  lib,
  pkgs,
  self,
  ...
}:
with lib;
let
  cfg = config.services.clash;
in
{
  options = {
    services.clash.enable = mkOption {
      type = types.bool;
      default = false;
    };

    services.clash.configFile = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.clash = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = self.data.systemdHarden // {
        StateDirectory = "%N";
        LoadCredential = "clash.conf:${cfg.configFile}";
        ExecStart = "${pkgs.clash-meta}/bin/clash-meta -d %S/%N -f \${CREDENTIALS_DIRECTORY}/clash.conf";
        PrivateNetwork = false;
        SystemCallFilter = "";
      };
    };

    presets.bpf-mark.clash = 1;
  };
}
