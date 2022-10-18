{ ... }:
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.initrd_ssh_host_ed25519_key = {};

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
}
