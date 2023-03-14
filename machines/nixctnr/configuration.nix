{ config, pkgs, ... }:
let
  host = "nixctnr";
in
{
  presets.nogui.enable = true;
  presets.nogui.enableNetwork = false;
  presets.impermanence.enable = false;

  nix.settings.auto-allocate-uids = false;

  boot.isContainer = true;
  boot.loader.initScript.enable = true;
  boot.initrd.systemd.enable = false;

  networking = {
    hostName = host;
    firewall.enable = false;
    nftables.enable = false;
    resolvconf.enable = false;
  };

  services.resolved.enable = false;
  services.openssh.listenAddresses = [{ addr = "[::1]"; port = 10022; }];
  systemd.network.wait-online.enable = false;

  documentation.nixos.enable = true;

  home-manager.users.rvfg = import ./home.nix;
}
