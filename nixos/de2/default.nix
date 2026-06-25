{
  inputs,
  nixpkgs,
  self,
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    inherit inputs self;
  };
  modules = [
    self.nixosModules.myModules
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./configuration.nix
    ./disko.nix
  ];
}
