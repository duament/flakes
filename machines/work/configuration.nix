{ config, pkgs, self, ... }:
let
  host = "work";
in
{
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
  networking.firewall = {
    checkReversePath = "loose";
    allowedTCPPorts = [
      config.services.squid.proxyPort
    ];
  };
  systemd.network.networks."80-ethernet" = {
    DHCP = "no";
    # dhcpV4Config = { SendOption = "50:ipv4address:172.26.0.2"; };
    address = [ "172.26.0.2/24" "fc00::2/64" ];
    gateway = [ "172.26.0.1" "fc00::1" ];
    dns = [ "10.9.231.5" ];
    domains = [ "~enflame.cn" "~h.rvf6.com" ];
  };
  presets.wireguard.wg0 = {
    enable = true;
    route = "all";
    routeBypass = [
      "172.16.0.0/12"
      "10.9.0.0/16"
      "fc00::/64"
    ];
  };

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
