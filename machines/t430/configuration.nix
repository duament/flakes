{ ... }:
{
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.initrd_ssh_host_ed25519_key = {};

  boot.loader = {
    generationsDir.copyKernels = true;
    systemd-boot.enable = true;
    systemd-boot.editor = false;
    timeout = 2;
  };
  boot.tmpOnTmpfs = false;

  networking.hostName = "t430";

  home-manager.users.rvfg = import ./home.nix;
}
