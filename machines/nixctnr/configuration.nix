{ config, pkgs, ... }:
let
  host = "nixctnr";
in
{
  presets.nogui.enable = true;
  presets.nogui.enableNetwork = false;

  boot.isContainer = true;

  networking = {
    hostName = host;
    firewall.enable = false;
    nftables.enable = false;
  };

  services.resolved.enable = false;
  systemd.services.systemd-networkd-wait-online.enable = false;

  home-manager.users.rvfg = import ./home.nix;
}
