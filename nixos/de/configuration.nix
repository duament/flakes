{ ... }:
{
  presets.nogui.enable = true;

  #sops.defaultSopsFile = ./secrets.yaml;
  #sops.secrets = {
  #  "wireguard_key".owner = "systemd-network";
  #};

  boot.loader.grub.enable = true;

  networking.hostName = "de";

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
