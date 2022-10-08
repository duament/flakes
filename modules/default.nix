{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    ./common.nix
    ./nftables
    ./nogui.nix
    ./router.nix
    ./shadowsocks
    ./smartdns.nix
    ./ssh-agent
    ./warp.nix
    ./wireguard-re-resolve.nix
    ./workstation.nix
  ];
}
