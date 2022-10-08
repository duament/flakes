{ inputs, ... }:
{
  imports = [
    inputs.nixos-cn.nixosModules.nixos-cn
    ./redir.nix
    ./tunnel.nix
  ];
}
