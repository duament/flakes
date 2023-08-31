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

    wsl = {
      url = "github:nix-community/NixOS-WSL";
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

          nom-suffix = "--log-format internal-json -v |& ${pkgs.nix-output-monitor}/bin/nom --json";

          deploy-script = pkgs.writeShellApplication {
            name = "deploy";
            text = ''
              if [ $# -ge 2 ]; then
                ACTION="$2"
              else
                ACTION=switch
              fi

              if [ $# -eq 0 ] || [ "$1" == "." ]; then
                exec sudo bash -c "TMPDIR=/var/tmp nixos-rebuild --flake . $ACTION ${nom-suffix}"
              else
                exec nixos-rebuild --flake .#"$1" --target-host deploy@"$1" --use-remote-sudo "$ACTION" ${nom-suffix}
              fi
            '';
          };

          update-script = pkgs.writeShellApplication {
            name = "update";
            text = ''
              nix flake update
            '';
            # cd pkgs
            # ${pkgs.nvfetcher}/bin/nvfetcher
          };

          build-script = pkgs.writeShellApplication {
            name = "build";
            text = ''
              if [ $# -eq 0 ]; then
                HOST="$(${pkgs.inetutils}/bin/hostname)"
              else
                HOST="$1"
              fi
              exec ${pkgs.nix-output-monitor}/bin/nom build .#nixosConfigurations."$HOST".config.system.build.toplevel
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
        wsl = import ./machines/wsl { inherit inputs nixpkgs self; };
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
