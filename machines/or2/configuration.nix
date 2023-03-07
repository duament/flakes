{ config, lib, pkgs, self, ... }:
let
  host = "or2";
in
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmpOnTmpfs = false;

  networking.hostName = host;

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1320;
  };

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
