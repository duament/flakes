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
    let
      data = import ./data { inherit inputs; inherit (nixpkgs) lib; };
    in
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
                exec nixos-rebuild --flake .#"$1" --target-host deploy@"$1" --use-remote-sudo --use-substitutes "$ACTION" ${nom-suffix}
              fi
            '';
          };

          update-script = pkgs.writeShellApplication {
            name = "update";
            text = ''
              nix flake update

              TOKEN_FILE_PATH="/run/secrets-rendered/nvchecker-github-token.toml"
              args=()
              if [[ -f "$TOKEN_FILE_PATH" ]]; then
                args=("-k" "$TOKEN_FILE_PATH")
              fi
              cd pkgs
              exec ${pkgs.nvfetcher}/bin/nvfetcher "''${args[@]}"
            '';
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

          sops = pkgs.writeShellApplication {
            name = "sops";
            text = ''
              exec ${pkgs.sops}/bin/sops --config ${pkgs.writeText "sops-config" data.sops.configText} "$@"
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

          apps.ci-deploy = {
            type = "app";
            program =
              let
                hosts = [ "az" "nl" "or2" ];
                known_hosts = pkgs.writeText "ssh_known_hosts" (builtins.concatStringsSep "" (map
                  (host:
                    "${host}.rvf6.com ${data.sshPub.${host}}\n"
                  )
                  hosts));
              in
              (pkgs.writeShellScript "ci-deploy" ''
                export NIX_SSHOPTS="-o GlobalKnownHostsFile=${known_hosts}"
                hosts=(${builtins.concatStringsSep " " hosts})
                for host in ''${hosts[*]}; do
                  echo "$host"
                  ${pkgs.nixos-rebuild}/bin/nixos-rebuild --flake .#"$host" --target-host deploy@"$host".rvf6.com --use-remote-sudo switch
                done
              '').outPath;
          };
        }
      )
    // {
      inherit data;

      overlays.default = final: _prev: import ./pkgs final;

      nixosModules.myModules = import ./modules;
      nixosModules.myHomeModules = import ./home-modules;

      nixosConfigurations = builtins.mapAttrs
        (k: v:
          import (./nixos + "/${k}") { inherit inputs nixpkgs self; }
        )
        (builtins.readDir ./nixos);

      homeConfigurations = builtins.mapAttrs
        (k: v:
          import (./home + "/${k}") { inherit inputs nixpkgs self; }
        )
        (builtins.readDir ./home);

      hydraJobs = {
        rpi3 = self.nixosConfigurations.rpi3.config.system.build.toplevel;
        or3 = self.nixosConfigurations.or3.config.system.build.toplevel;
      };
    };
}
