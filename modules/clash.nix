{ config, lib, pkgs, ... }:
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
      wantedBy = [ "multi-user.target" ];
      serviceConfig = import ../lib/systemd-harden.nix // {
        StateDirectory = "%N";
        LoadCredential = "clash.conf:${cfg.configFile}";
        ExecStart = "${pkgs.clash}/bin/clash -d %S/%N -f \${CREDENTIALS_DIRECTORY}/clash.conf";
        PrivateNetwork = false;
      };
    };
  };
}
