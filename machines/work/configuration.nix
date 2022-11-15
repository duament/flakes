{ config, pkgs, ... }:
let
  host = "work";
  wg0 = import ../../lib/wg0.nix;
  wgMark = 8;
  wgTable = 1000;
in {
  #nixpkgs.overlays = [
  #  (self: super: {
  #    llvmPackages_14 = super.llvmPackages_14 // {
  #      compiler-rt = super.llvmPackages_14.compiler-rt.overrideAttrs (oldAttrs: {
  #        cmakeFlags = oldAttrs.cmakeFlags ++ [ "-DCOMPILER_RT_TSAN_DEBUG_OUTPUT=ON" ];
  #      });
  #    };
  #  })
  #];

  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.wireguard_key.owner = "systemd-network";

  boot.loader.systemd-boot.enable = true;

  boot.tmpOnTmpfs = false;

  networking.hostName = host;
  networking.firewall.allowedTCPPorts = [
    config.services.squid.proxyPort
  ];

  systemd.network.networks."80-ethernet" = {
    DHCP = "no";
    # dhcpV4Config = { SendOption = "50:ipv4address:172.26.0.2"; };
    address = [ "172.26.0.2/24" "fc00::2/64" ];
    gateway = [ "172.26.0.1" "fc00::1" ];
    dns = [ "10.9.231.5" ];
    domains = [ "~enflame.cn" "~h.rvf6.com" ];
  };
  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      FirewallMark = wgMark;
    };
    wireguardPeers = [ { wireguardPeerConfig = {
      AllowedIPs = [ "0.0.0.0/0" "::/0" ];
      Endpoint = wg0.endpoint;
      PersistentKeepalive = 25;
      PublicKey = wg0.pubkey;
    }; } ];
  };
  systemd.network.networks."25-wg0" = {
    enable = true;
    name = "wg0";
    address = [ "${wg0.peers.${host}.ipv4}/24" "${wg0.peers.${host}.ipv6}/120" ];
    dns = [ wg0.gateway6 ];
    domains = [ "~." ];
    networkConfig = { DNSDefaultRoute = "yes"; };
    routingPolicyRules = [
      {
        routingPolicyRuleConfig = {
          Family = "both";
          FirewallMark = wgMark;
          InvertRule = "yes";
          Table = wgTable;
          Priority = 10;
        };
      }
      {
        routingPolicyRuleConfig = {
          To = "172.16.0.0/12";
          Priority = 9;
        };
      }
      {
        routingPolicyRuleConfig = {
          To = "10.9.0.0/16";
          Priority = 9;
        };
      }
      {
        routingPolicyRuleConfig = {
          To = "fc00::/64";
          Priority = 9;
        };
      }
    ];
    routes = [
      {
        routeConfig = {
          Destination = "0.0.0.0/0";
          Table = wgTable;
        };
      }
      {
        routeConfig = {
          Destination = "::/0";
          Table = wgTable;
        };
      }
    ];
  };
  services.wireguardReResolve.interfaces = [ "wg0" ];

  users.users.rvfg.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkJYJCkj7fPff31pDkGULXhgff+jaaj4BKu1xzL/DeZ enflame"
  ];

  home-manager.users.rvfg = import ./home.nix;

  services.squid = {
    enable = true;
    proxyAddress = "[::]";
    extraConfig = ''
    '';
  };
}
