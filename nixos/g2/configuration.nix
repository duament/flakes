{ self, ... }:
{

  presets.nogui.enable = true;
  presets.disko = {
    enable = true;
    biosBoot = true;
    device = "/dev/sda";
  };
  presets.nginx.enable = true;
  presets.swanctl-gfw.enableServer = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/g2-bundle" = { };
    "pki/g2-pkcs8-key" = { };
  };

  networking.hostName = "g2";

  systemd.network.networks."10-enp3s0" = {
    name = "enp3s0";
    address = [
      "${self.data.dns.g2.ipv6}/64"
      "${self.data.dns.g2.ipv4}/24"
    ];
    dns = [
      "2001:4860:4860::8888"
      "2606:4700:4700::1111"
      "8.8.8.8"
      "1.1.1.1"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "2a12:a303:11e::1";
        GatewayOnLink = true;
      }
      {
        Gateway = "109.121.61.254";
        GatewayOnLink = true;
      }
    ];
  };

  home-manager.users.rvfg = import ./home.nix;

}
