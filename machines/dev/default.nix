{ nixpkgs, inputs }: inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages."x86_64-linux";
  modules = [
    ./home.nix
  ];
}