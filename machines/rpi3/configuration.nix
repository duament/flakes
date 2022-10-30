{ ... }:
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    initrd_ssh_host_ed25519_key = {};
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;

  boot.tmpOnTmpfs = false;

  networking.hostName = "rpi3";

  home-manager.users.rvfg = import ./home.nix;
}
