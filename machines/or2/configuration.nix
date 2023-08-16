{ config, self, ... }:
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "or2";

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1320;
  };

  systemd.network.netdevs."25-wg-or2" = {
    netdevConfig = {
      Name = "wg-or2";
      Kind = "wireguard";
      MTUBytes = "1400";
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = 11112;
    };
    wireguardPeers = [{
      wireguardPeerConfig = {
        AllowedIPs = [ "0.0.0.0/0" "::/0" ];
        PublicKey = self.data.wg0.pubkey;
      };
    }];
  };
  systemd.network.networks."25-wg-or2" = {
    name = "wg-or2";
    address = [ "10.6.9.2/24" "fd66::2/120" ];
    networkConfig.IPForward = true;
  };
  networking.firewall = {
    allowedUDPPorts = [ 11112 ];
    extraForwardRules = ''
      iifname wg-or2 accept
    '';
  };
  networking.nftables.masquerade = [ "iifname wg-or2" ];

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
