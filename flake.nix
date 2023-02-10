{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:duament/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    nixos-cn = {
      url = "github:nixos-cn/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
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
    inputs.flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ]
      (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          formatter = pkgs.nixpkgs-fmt;
          packages = import ./pkgs pkgs;
        }
      )
    // {
      nixosModules.myModules = import ./modules;
      nixosModules.myHomeModules = import ./home-modules;

      nixosConfigurations = {
        desktop = import ./machines/desktop { inherit inputs nixpkgs self; };
        work = import ./machines/work { inherit inputs nixpkgs self; };
        rpi3 = import ./machines/rpi3 { inherit inputs nixpkgs self; };
        t430 = import ./machines/t430 { inherit inputs nixpkgs self; };
        or2 = import ./machines/or2 { inherit inputs nixpkgs self; };
        or3 = import ./machines/or3 { inherit inputs nixpkgs self; };
        az = import ./machines/az { inherit inputs nixpkgs self; };
        nl = import ./machines/nl { inherit inputs nixpkgs self; };
        nixctnr = import ./machines/nixctnr { inherit inputs nixpkgs self; };
      };

      homeConfigurations = {
        dev = import ./machines/dev { inherit inputs nixpkgs self; };
      };

      hydraJobs = {
        rpi3 = self.nixosConfigurations.rpi3.config.system.build.toplevel;
        or3 = self.nixosConfigurations.or3.config.system.build.toplevel;
      };
    };
}
