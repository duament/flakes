{ inputs, nixpkgs, self }: nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  specialArgs = { inherit inputs nixpkgs self; };
  modules = [
    self.nixosModules.myModules
    ./hardware-configuration.nix
    ./configuration.nix
  ];
}
