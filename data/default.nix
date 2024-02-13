{ inputs, lib, ... }:
{
  nftChinaIP = import ./nft-china-ip.nix { inherit inputs lib; };
  sops = import ./sops.nix;
  sshPub = import ./ssh-pubkeys.nix;
  syncthing = import ./syncthing.nix;
  systemdHarden = import ./systemd-harden.nix;
  tailscale = import ./tailscale.nix;
  ublockOriginSettings = import ./ublock-origin-settings.nix;
  wg0 = import ./wg0.nix;
}
