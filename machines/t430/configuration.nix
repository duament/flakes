{ ... }:
{
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