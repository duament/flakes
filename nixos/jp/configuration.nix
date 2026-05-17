{ ... }:
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  presets.users.hashedPasswordFile = null;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "jp";

  systemd.network.networks."10-ens3" = {
    name = "ens3";
    address = [
      "2403:71c0:2000:133b::a/64"
      "172.93.220.78/24"
    ];
    dns = [
      "8.8.8.8"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "2403:71c0:2000::1";
        GatewayOnLink = true;
      }
      {
        Gateway = "172.93.220.1";
        GatewayOnLink = true;
      }
    ];
  };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1400;
  };

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
