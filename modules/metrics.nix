{ config, lib, ... }:
let
  cfg = config.presets.metrics;
in
{
  options = {
    presets.metrics.enable = lib.mkEnableOption "export server metrics";
  };

  config = lib.mkIf cfg.enable {
    services.telegraf = {
      enable = true;
      extraConfig = {
        inputs = {
          cpu = { };
          disk = {
            ignore_fs = [
              "tmpfs"
              "devtmpfs"
              "devfs"
              "overlay"
              "aufs"
              "squashfs"
            ];
            ignore_mount_opts = [ "bind" ];
          };
          diskio = { };
          mem = { };
          net = { };
          processes = { };
          system = { };
          systemd_units = { };
        };
        outputs = {
          prometheus_client = {
            listen = "[::1]:9273";
            metric_version = 2;
            path = "/metrics";
          };
        };
      };
    };

    services.nginx.virtualHosts."${config.networking.hostName}.rvf6.com".locations."/metrics" = {
      proxyPass = "http://${config.services.telegraf.extraConfig.outputs.prometheus_client.listen}";
    };
  };
}
