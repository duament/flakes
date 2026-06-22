{ ... }:
{

  imports = [
    # keep-sorted start
    ./swanctl.nix
    # keep-sorted end
  ];

  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/de-bundle" = { };
    "pki/de-pkcs8-key" = { };
  };

  boot.loader.grub.enable = true;

  networking.hostName = "de";

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
