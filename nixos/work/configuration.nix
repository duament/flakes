{ ... }:
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

  networking.hostName = "work";
  networking.firewall = {
    checkReversePath = "loose";
    allowedTCPPorts = [
      1080
    ];
  };
  systemd.network.networks."80-ethernet" = {
    matchConfig = { Type = "ether"; };
    DHCP = "no";
    # dhcpV4Config = { SendOption = "50:ipv4address:172.26.0.2"; };
    address = [ "172.26.0.2/24" "fc00::2/64" ];
    gateway = [ "172.26.0.1" "fc00::1" ];
    dns = [ "10.9.231.5" ];
    domains = [ "~enflame.cn" "~h.rvf6.com" ];
    routingPolicyRules = map
      (ip:
        {
          To = ip;
          Priority = 9;
        }
      ) [ "172.16.0.0/12" "10.9.0.0/16" "10.12.0.0/16" "fc00::/64" ];
  };
  presets.wireguard.wg0 = {
    enable = false;
    clientPeers.t430 = {
      route = "all";
      routeBypass = [
        "172.16.0.0/12"
        "10.9.0.0/16"
        "10.12.0.0/16"
        "fc00::/64"
      ];
    };
  };

  services.tailscale.enable = true;

  users.users.rvfg.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkJYJCkj7fPff31pDkGULXhgff+jaaj4BKu1xzL/DeZ enflame"
  ];

  home-manager.users.rvfg = import ./home.nix;

  environment.persistence."/persist".users.rvfg = {
    directories = [
      "Downloads"
    ];
  };

  presets.sing-box = {
    enable = true;
    settings = {
      inbounds = [
        {
          type = "socks";
          listen = "::";
          listen_port = 1080;
        }
      ];
      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
        {
          type = "http";
          tag = "http";
          server = "t430.rvf6.com";
          server_port = 8000;
        }
      ];
      route.rules = [
        {
          domain_suffix = [
            "byr.pt"
            "reddit.com"
          ];
          domain = [ "prod-ingress.nianticlabs.com" ];
          outbound = "http";
        }
      ];
    };
  };

}
