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

  networking.firewall = {
    interfaces.gre-jp3.allowedTCPPorts = [ 8000 ];
    extraInputRules = ''
      iifname wg-jp3 ip protocol gre accept
    '';
    extraForwardRules = ''
      iifname gre-jp3 accept
    '';
  };
  systemd.network.netdevs."30-gre-jp3" = {
    netdevConfig = {
      Name = "gre-jp3";
      Kind = "gre";
    };
    tunnelConfig = {
      Local = "10.6.19.30";
      Remote = "10.5.0.50";
      Independent = true;
    };
  };
  systemd.network.networks."30-gre-jp3" = {
    name = "gre-jp3";
    address = [
      "10.5.1.5/30"
      "fdc1::5/126"
    ];
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

  networking.nftables.masquerade = [
    "iifname xfrm-jp3 oifname ens5"
    "iifname gre-jp3"
  ];

  home-manager.users.rvfg = import ./home.nix;

}
