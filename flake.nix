{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:duament/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cn = {
      url = "github:nixos-cn/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chn-cidr-list = {
      url = "github:fernvenue/chn-cidr-list";
      flake = false;
    };

    dnsmasq-china-list = {
      url = "github:felixonmars/dnsmasq-china-list";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
  {
    nixosModules.myModules = import ./modules;
    nixosModules.myHomeModules = import ./home-modules;

    nixosConfigurations = {
      desktop = import ./machines/desktop { inherit inputs nixpkgs self; };
      work = import ./machines/work { inherit inputs nixpkgs self; };
      rpi3 = import ./machines/rpi3 { inherit inputs nixpkgs self; };
      t430 = import ./machines/t430 { inherit inputs nixpkgs self; };
    };

    homeConfigurations = {
      dev = import ./machines/dev { inherit inputs nixpkgs self; };
    };
  };
}
