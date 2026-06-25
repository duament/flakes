{ ... }:
{

  imports = [
    # keep-sorted start
    ./swanctl.nix
    # keep-sorted end
  ];

  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/de2-bundle" = { };
    "pki/de2-pkcs8-key" = { };
  };

  boot.loader.grub.enable = true;

  networking.hostName = "de2";

  systemd.network.networks."10-ens3" = {
    name = "ens3";
    address = [
      "82.115.30.220/24"
    ];
    dns = [
      "8.8.8.8"
      "1.1.1.1"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "82.115.30.1";
        GatewayOnLink = true;
      }
    ];
  };

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
