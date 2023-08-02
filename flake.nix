{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:duament/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
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

          deploy-script = pkgs.writeShellApplication {
            name = "deploy";
            text = ''
              if [ $# -eq 0 ]; then
                sudo nixos-rebuild --flake . switch
              elif [ $# -eq 1 ] ; then
                nixos-rebuild --flake .#"$1" --target-host deploy@"$1" --use-remote-sudo switch
              else
                nixos-rebuild --flake .#"$1" --target-host deploy@"$1" --use-remote-sudo "$2"
              fi
            '';
          };

          update-script = pkgs.writeShellApplication {
            name = "update";
            text = ''
              nix flake update
              cd pkgs
              ${pkgs.nvfetcher}/bin/nvfetcher
            '';
          };

          build-script = pkgs.writeShellApplication {
            name = "build";
            text = ''
              nix build .#nixosConfigurations."$1".config.system.build.toplevel
            '';
          };

          sops-config = pkgs.writeText "sops-config" (import ./data/sops-config.nix);
          sops = pkgs.writeShellApplication {
            name = "sops";
            text = ''
              exec ${pkgs.sops}/bin/sops --config ${sops-config} "$@"
            '';
          };
        in
        {
          formatter = pkgs.nixpkgs-fmt;

          packages = import ./pkgs pkgs;

          devShells.default = pkgs.mkShell {
            packages = [
              deploy-script
              update-script
              build-script
              sops
            ];
          };
        }
      )
    // {
      data = import ./data { inherit inputs; inherit (nixpkgs) lib; };

      nixosModules.myModules = import ./modules;
      nixosModules.myHomeModules = import ./home-modules;

      nixosConfigurations = {
        desktop = import ./machines/desktop { inherit inputs nixpkgs self; };
        xiaoxin = import ./machines/xiaoxin { inherit inputs nixpkgs self; };
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
