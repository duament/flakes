{ config, pkgs, ... }:
{
  imports = [
    ../../modules/nogui.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.wireguard_key.owner = "systemd-network";
  };

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
  };

  networking.hostName = "rpi3";
  networking.nftables = {
    inputAccept = ''
      udp dport 11112 accept comment "wireguard"
    '';
    forwardAccept = ''
      iifname wg0 accept;
      oifname wg0 accept;
    '';
    masquerade = [ "oifname \"eth0\"" ];
    tproxy = {
      enable = true;
      enableLocal = true;
      src = ''
        ip saddr 10.6.6.0/24 return;
      '';
      dst = ''
        ip daddr 17.0.0.0/8 accept comment "Apple"
      '';
    };
  };

  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = 11112;
    };
    wireguardPeers = [ { wireguardPeerConfig = {
      AllowedIPs = [ "10.6.6.3/32" ];
      PersistentKeepalive = 25;
      PublicKey = "BcLh8OUygmCL2m50MREgsAwOLMkF9A+eAhuQDEPaqWI=";
    }; } ];
  };
  systemd.network.networks."25-wg0" = {
    enable = true;
    name = "wg0";
    address = [ "10.6.6.2/24" ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.rvfg = import ./home.nix;
  };

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "22.11";
}

