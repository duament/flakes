{ ... }:
{

  presets.nogui.enable = true;
  presets.disko = {
    enable = true;
    biosBoot = true;
  };
  presets.nginx.enable = true;
  presets.swanctl-gfw.enableServer = false;

  #sops.defaultSopsFile = ./secrets.yaml;
  #sops.secrets = {
  #  "pki/ca".mode = "0444";
  #  "pki/ybk".mode = "0444";
  #  "pki/jp3-bundle" = { };
  #  "pki/jp3-pkcs8-key" = { };
  #};

  presets.users.hashedPasswordFile = null;

  networking.hostName = "jp3";

  home-manager.users.rvfg = import ./home.nix;

}
