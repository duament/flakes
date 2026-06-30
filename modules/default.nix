{ inputs, ... }:
{
  imports = [
    # keep-sorted start
    ./adguardhome.nix
    ./avbroot.nix
    ./bpf-mark.nix
    ./chromium.nix
    ./clash.nix
    ./common.nix
    ./disko.nix
    ./duckdns.nix
    ./fs.nix
    ./gammu-smsd.nix
    ./git.nix
    ./github-token.nix
    ./metrics.nix
    ./nftables
    ./nginx.nix
    ./nogui.nix
    ./postgresql.nix
    ./preservation.nix
    ./refind
    ./restic.nix
    ./router.nix
    ./shadowsocks.nix
    ./sing-box.nix
    ./smartdns.nix
    ./ssh-agent.nix
    ./swanctl-dynamic-ipv6.nix
    ./swanctl-gfw
    ./swanctl-static.nix
    ./traefik.nix
    ./users.nix
    ./uu.nix
    ./vouch.nix
    ./warp.nix
    ./wireguard
    ./workstation.nix
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.preservation.nixosModules.preservation
    inputs.sops-nix.nixosModules.sops
    # keep-sorted end
  ];
}
