{ config, pkgs, ... }:
{
  imports = [
    ../../modules/nogui.nix
  ];

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  networking.hostName = "rpi3";
  networking.nftables = {
    inputAccept = ''
      udp dport 11112 accept comment "wireguard"
    '';
    masquerade = [ "oifname \"eth0\"" ];
    tproxy = {
      enable = false;
      enableLocal = true;
      src = ''
        ip saddr 10.6.6.0/24 return;
      '';
      dst = ''
        ip daddr 17.0.0.0/8 accept comment "Apple"
      '';
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.rvfg = import ./home.nix;
  };

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "22.11";
}

