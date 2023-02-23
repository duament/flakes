{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    ./chromium.nix
    ./clash.nix
    ./common.nix
    ./git.nix
    ./nftables
    ./nogui.nix
    ./refind
    ./router.nix
    ./shadowsocks
    ./smartdns.nix
    ./ssh-agent.nix
    ./swanctl-dynamic-ipv6.nix
    ./traefik.nix
    ./users.nix
    ./uu.nix
    ./vouch.nix
    ./warp.nix
    ./wireguard-dynamic-ipv6.nix
    ./wireguard-keep-alive.nix
    ./wireguard-re-resolve.nix
    ./workstation.nix
  ];
}
