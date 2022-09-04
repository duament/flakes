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

    nixos-cn = {
      url = "github:nixos-cn/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chnroutes2 = {
      url = "github:misakaio/chnroutes2";
      flake = false;
    };

    china-operator-ip = {
      url = "github:gaoyifan/china-operator-ip/ip-lists";
      flake = false;
    };

    dnsmasq-china-list = {
      url = "github:felixonmars/dnsmasq-china-list";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
  {
    nixosConfigurations = {
      desktop = import ./machines/desktop { inherit nixpkgs inputs; };
      work = import ./machines/work { inherit nixpkgs inputs; };
      rpi3 = import ./machines/rpi3 { inherit nixpkgs inputs; };
    };

    homeConfigurations = {
      dev = import ./machines/dev { inherit nixpkgs inputs; };
    };
  };
}
