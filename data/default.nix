{ inputs, lib, ... }:
{
  sshPub = import ./ssh-pubkeys.nix;
  wg0 = import ./wg0.nix;
  syncthing = import ./syncthing.nix;
  nftChinaIP = import ./nft-china-ip.nix { inherit inputs lib; };
  systemdHarden = import ./systemd-harden.nix;
}
