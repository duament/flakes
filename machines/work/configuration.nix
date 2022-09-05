{ config, pkgs, ... }:
let
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

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.tmpOnTmpfs = false;

  networking.hostName = "work";
  networking.nftables.inputAccept = ''
    tcp dport 3128 accept comment "squid"
  '';
  #networking.extraHosts = "223.166.103.111 h.rvf6.com";

  systemd.network.networks."80-ethernet" = {
    DHCP = "no";
    # dhcpV4Config = { SendOption = "50:ipv4address:172.26.0.2"; };
    address = [ "172.26.0.2/24" ];
    gateway = [ "172.26.0.1" ];
    dns = [ "223.5.5.5" ];
    domains = [ "~h.rvf6.com" ];
  };
  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
    wireguardConfig = {
      PrivateKeyFile = "/etc/wireguard/secret.key";
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
    address = [ "${wg0.peers.work.ip}/32" ];
    dns = [ wg0.gateway ];
    domains = [ "~." ];
    networkConfig = { DNSDefaultRoute = "yes"; };
    routingPolicyRules = [
      {
        routingPolicyRuleConfig = {
          FirewallMark = wgMark;
          InvertRule = "yes";
          Table = wgTable;
          Priority = 10;
        };
      }
      {
        routingPolicyRuleConfig = {
          To = "172.26.0.2/24";
          Priority = 9;
        };
      }
    ];
    routes = [ { routeConfig = {
      Gateway = wg0.gateway;
      GatewayOnLink = "yes";
      Table = wgTable;
    }; } ];
  };

  users.users.rvfg.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkJYJCkj7fPff31pDkGULXhgff+jaaj4BKu1xzL/DeZ enflame"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.rvfg = import ./home.nix;
  };

  #environment.systemPackages = with pkgs; [
  #];

  services.squid = {
    enable = true;
    proxyAddress = "0.0.0.0";
    extraConfig = ''
      acl ip_acl src 192.168.0.0/16
      http_access allow ip_acl
    '';
  };

  system.stateVersion = "22.11";
}
