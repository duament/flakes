{ config, self, ... }:
let
  nonCNMark = 2;
in
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    initrd_ssh_host_ed25519_key = { };
    "pki/ca" = { };
    "pki/ybk" = { };
    "pki/bundle" = { };
    "pki/pkcs8-key" = { };
    warp_key.owner = "systemd-network";
    duckdns = { };
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;

  networking.hostName = "rpi3";

  systemd.network.networks."10-enu1u1u1" = {
    matchConfig.PermanentMACAddress = "b8:27:eb:f0:2e:8e";
    DHCP = "yes";
    dhcpV6Config.PrefixDelegationHint = "::/63";
  };

  services.uu = {
    enable = true;
    vlan = {
      enable = true;
      parentName = "10-enu1u1u1";
    };
  };

  networking.warp = {
    enable = true;
    endpointAddr = "162.159.192.1";
    mtu = 1412;
    mark = 3;
    routingId = "0x29478c";
    keyFile = config.sops.secrets.warp_key.path;
    address = [ "172.16.0.2/32" "2606:4700:110:81f3:a59c:d5a7:d339:59b8/128" ];
    table = 20;
  };
  presets.wireguard.keepAlive.interfaces = [ "warp" ];
  networking.firewall = {
    checkReversePath = "loose";
    extraInputRules = ''
      ip saddr { 10.7.0.1, ${self.data.tailscale.ipv4} } meta l4proto { tcp, udp } th dport 53 accept
    '';
    extraForwardRules = ''
      ip saddr { 10.7.0.1, ${self.data.tailscale.ipv4} } accept
      ip6 saddr { ${self.data.tailscale.ipv6} } accept
    '';
  };
  networking.nftables.mssClamping = true;
  networking.nftables.masquerade = [ "ip saddr { ${self.data.tailscale.ipv4} }" "ip6 saddr { ${self.data.tailscale.ipv6} }" ];
  networking.nftables.markChinaIP = {
    enable = true;
    mark = nonCNMark;
  };
  systemd.network.networks."25-warp".routingPolicyRules =
    let
      table = 20;
    in
    [
      {
        FirewallMark = nonCNMark;
        Table = table;
        Priority = 20;
        Family = "both";
      }
      {
        To = "34.117.196.143"; # prod-ingress.nianticlabs.com
        Table = "main";
        Priority = 9;
      }
      {
        To = "2001:da8:215:4078:250:56ff:fe97:654d"; # byr.pt
        Table = table;
        Priority = 9;
      }
    ];
  presets.smartdns = {
    enable = true;
    chinaDns = [ "[fd69:2011:6f1d::1]" ];
    settings.address = [
      "/t430.rvf6.com/10.6.6.1"
      "/t430.rvf6.com/fd64::1"
      "/ax6s.rvf6.com/fd65::1"
      "/ax6s.rvf6.com/-4"
      "/rpi3.rvf6.com/10.7.0.7"
      "/fava.rvf6.com/fd64::1"
      "/fava.rvf6.com/-4"
      "/luci.rvf6.com/fd64::1"
      "/luci.rvf6.com/-4"
      "/ha.rvf6.com/fd64::1"
      "/ha.rvf6.com/-4"
    ];
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    port = 4164;
    extraUpFlags = [
      "--accept-dns=false"
      "--advertise-exit-node"
      "--netfilter-mode=off"
    ];
  };
  presets.bpf-mark.tailscaled = 1;

  presets.duckdns = {
    enable = true;
    domain = "rpi3-rvfg.duckdns.org";
    interface = "enu1u1u1";
    tokenFile = config.sops.secrets.duckdns.path;
  };

  services.swanctlDynamicIPv6 = {
    enable = true;
    underlyingNetwork = "10-enu1u1u1";
    IPv6Middle = ":1";
    IPv4Prefix = "10.7.6.";
    privateKeyFile = config.sops.secrets."pki/pkcs8-key".path;
    local.rpi3 = {
      auth = "pubkey";
      id = "rpi3.rvf6.com";
      certs = [ config.sops.secrets."pki/bundle".path ];
    };
    cacerts = [ config.sops.secrets."pki/ca".path config.sops.secrets."pki/ybk".path ];
    devices = [ "ip13" "pixel7" "xiaoxin" ];
  };

  home-manager.users.rvfg = import ./home.nix;
}
