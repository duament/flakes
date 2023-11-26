{ config, self, ... }:
{
  presets.nogui.enable = true;
  # presets.metrics.enable = true;

  # sops.defaultSopsFile = ./secrets.yaml;
  # sops.secrets = {
  #   "wireguard_key".owner = "systemd-network";
  # };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    fsIdentifier = "label";
  };

  networking.hostName = "ak";

  systemd.network.networks."10-ens18" = {
    name = "ens18";
    address = [ "2401:b60:5:4a91:bd28:4be0:ccd2:80da/64" "203.147.229.50/23" ];
    gateway = [ "203.147.228.1" ];
    dns = [ "2606:4700:4700::1111" "1.1.1.1" "8.8.8.8" ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        routeConfig = {
          Gateway = "2401:b60:5::1";
          GatewayOnLink = true;
        };
      }
    ];
  };

  # presets.wireguard.wg0 = {
  #   enable = true;
  #   mtu = 1320;
  # };

  # systemd.network.netdevs."25-wg-or2" = {
  #   netdevConfig = {
  #     Name = "wg-or2";
  #     Kind = "wireguard";
  #     MTUBytes = "1400";
  #   };
  #   wireguardConfig = {
  #     PrivateKeyFile = config.sops.secrets.wireguard_key.path;
  #     ListenPort = 11112;
  #   };
  #   wireguardPeers = [{
  #     wireguardPeerConfig = {
  #       AllowedIPs = [ "0.0.0.0/0" "::/0" ];
  #       PublicKey = self.data.wg0.pubkey;
  #     };
  #   }];
  # };
  # systemd.network.networks."25-wg-or2" = {
  #   name = "wg-or2";
  #   address = [ "10.6.9.2/24" "fd66::2/120" ];
  #   networkConfig.IPForward = true;
  # };
  # networking.firewall = {
  #   allowedUDPPorts = [ 11112 ];
  #   extraForwardRules = ''
  #     iifname wg-or2 accept
  #   '';
  # };
  # networking.nftables.masquerade = [ "iifname wg-or2" ];

  # home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
