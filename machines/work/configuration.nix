{ config, pkgs, ... }:
{
  imports = [
    ../../modules/nogui.nix
  ];

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
      FirewallMark = 8;
    };
    wireguardPeers = [ { wireguardPeerConfig = {
      AllowedIPs = [ "0.0.0.0/0" "::/0" ];
      Endpoint = "h.rvf6.com:11111";
      PersistentKeepalive = 25;
      PublicKey = "OXMopf5h0m7x2udIdCR7qxBhniN5+coCGqbrm99Lgi4=";
    }; } ];
  };
  systemd.network.networks."25-wg0" = {
    enable = true;
    name = "wg0";
    address = [ "10.0.0.10/32" ];
    dns = [ "192.168.2.1" ];
    domains = [ "~." ];
    networkConfig = { DNSDefaultRoute = "yes"; };
    routingPolicyRules = [
      {
        routingPolicyRuleConfig = {
          FirewallMark = 8;
          InvertRule = "yes";
          Table = 1000;
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
      Gateway = "10.0.0.1";
      GatewayOnLink = "yes";
      Table = 1000;
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
