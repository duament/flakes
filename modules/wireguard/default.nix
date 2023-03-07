{ ... }:
{
  imports = [
    ./dynamic-ipv6.nix
    ./keep-alive.nix
    ./re-resolve.nix
    ./wg0.nix
  ];
}
