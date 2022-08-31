{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
  {
    nixosConfigurations = {
      desktop = import ./machines/desktop { inherit nixpkgs inputs; };
      work = import ./machines/work { inherit nixpkgs inputs; };
      rpi3 = import ./machines/rpi3 { inherit nixpkgs inputs; };
    };
  };
}
