{ ... }:
{

  imports = [
    ./swanctl.nix
  ];

  presets.nogui.enable = true;
  presets.disko = {
    enable = true;
    biosBoot = true;
    device = "/dev/nvme0n1";
  };
  presets.nginx.enable = true;
  presets.swanctl-gfw.enableServer = true;

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1400;
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/jp3-bundle" = { };
    "pki/jp3-pkcs8-key" = { };
  };

  networking.hostName = "jp3";

  systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.UseMTU = true;

  networking.nftables.masquerade = [ "iifname xfrm-jp3 oifname ens5" ];

  home-manager.users.rvfg = import ./home.nix;

}
