{ config, lib, ... }:
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    initrd_ssh_host_ed25519_key = {};
    swanctl = {};
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;
  boot.tmpOnTmpfs = false;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.hostName = "t430";

  home-manager.users.rvfg = import ./home.nix;

  services.uu.enable = true;

  services.strongswan-swanctl.enable = true;
  services.strongswan-swanctl.strongswan.extraConfig = ''
    charon {
      plugins {
        attr {
          dns = 223.5.5.5
        }
      }
    }
  '';
  environment.etc."swanctl/swanctl.conf".enable = false;
  system.activationScripts.strongswan-swanctl-secret-conf = lib.stringAfter ["etc"] ''
    mkdir -p /etc/swanctl
    ln -sf ${config.sops.secrets.swanctl.path} /etc/swanctl/swanctl.conf
  '';
  networking.nftables.inputAccept = ''
    ip protocol { ah, esp } accept
    udp dport { 500, 4500 } accept
  '';
  networking.nftables.forwardAccept = ''
    meta ipsec exists accept
    rt ipsec exists accept
  '';
}
