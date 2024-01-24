{ config, lib, pkgs, self, ... }:
let
  inherit (lib) types mkOption mkEnableOption;
  cfg = config.presets.uutunnel;
in
{
  options.presets.uutunnel = {
    enable = mkEnableOption "";

    configFile = mkOption {
      type = types.path;
      default = "/var/lib/uutunnel/uutunnel.conf";
    };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      uutunnel
    ];

    systemd.services.uutunnel = {
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = self.data.systemdHarden // {
        EnvironmentFile = "-${cfg.configFile}";
        ExecStart = "${pkgs.uutunnel}/bin/uutunnel";
        PrivateNetwork = false;
      };
    };

  };
}
