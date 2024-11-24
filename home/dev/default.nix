{
  inputs,
  nixpkgs,
  self,
}:
let
  system = "x86_64-linux";
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.${system};
  modules = [
    ./home.nix
  ];
  extraSpecialArgs = {
    inherit inputs self;
    sysConfig = null;
  };
}
