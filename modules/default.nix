{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    ./chromium.nix
    ./clash.nix
    ./common.nix
    ./gammu-smsd.nix
    ./git.nix
    ./nftables
    ./nginx.nix
    ./nogui.nix
    ./refind
    ./router.nix
    ./smartdns.nix
    ./ssh-agent.nix
    ./swanctl-dynamic-ipv6.nix
    ./traefik.nix
    ./users.nix
    ./uu.nix
    ./vouch.nix
    ./warp.nix
    ./wireguard
    ./workstation.nix
  ];
}
