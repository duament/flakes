{
  config,
  pkgs,
  self,
  ...
}:
let
  sources = pkgs.callPackage self.sources { };
  inherit (config.services.home-assistant.package.python3Packages) callPackage;

  haier = callPackage ./haier.nix { source = sources.haier; };
  midea_auto_cloud = callPackage ./midea_auto_cloud.nix { source = sources.midea_auto_cloud; };
in
{

  sops.secrets."home-assistant-secrets.yaml" = {
    owner = "hass";
    path = "/var/lib/hass/secrets.yaml";
  };

  networking.firewall = {
    extraInputRules = ''
      iifname v1-lan tcp dport ${toString config.services.home-assistant.config.homekit.port} accept
      iifname v1-lan udp dport 5353 accept
    '';
  };

  services.home-assistant = {
    enable = true;
    config = {
      default_config = { };
      homeassistant = {
        name = "Home";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = "!secret elevation";
        unit_system = "metric";
        time_zone = config.time.timeZone;
      };
      http = {
        server_host = "::1";
        use_x_forwarded_for = true;
        trusted_proxies = [ "::1/128" ];
      };
      homekit = {
        port = 21063;
        advertise_ip = [
          "10.8.0.1"
          "fdd0::1"
        ];
      };
    };
    extraComponents = [
      "default_config"
      "esphome"
      "ffmpeg"
      "met"
      "xiaomi_miio"
      "roborock"
      "bthome"
      "homekit"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      xiaomi_miot
      haier
      midea_auto_cloud
    ];
    extraPackages =
      python3Packages: with python3Packages; [
        hap-python
        pyqrcode
      ];
  };

  presets.nginx.virtualHosts."ha.rvf6.com".locations."/" = {
    proxyPass = "http://[::1]:${toString config.services.home-assistant.config.http.server_port}";
    proxyWebsockets = true;
  };

}
