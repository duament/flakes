{ inputs, nixpkgs, self }: nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    inherit inputs self;
  };
  modules = [
    self.nixosModules.myModules
    ./configuration.nix
  ];
}
