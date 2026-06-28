{ ... }:
{

  presets.nogui.enable = true;
  presets.swanctl-gfw.enableServer = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/de-bundle" = { };
    "pki/de-pkcs8-key" = { };
  };

  boot.loader.grub.enable = true;

  boot.kernel.sysctl = {
    "net.core.wmem_max" = 33554432;
    "net.ipv4.tcp_wmem" = "4096 65536 33554432";
  };

  networking.hostName = "de";

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
