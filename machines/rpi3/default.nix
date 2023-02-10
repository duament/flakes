{ inputs, nixpkgs, self }: nixpkgs.lib.nixosSystem rec {
  system = "aarch64-linux";
  specialArgs = {
    inherit inputs nixpkgs self;
    mypkgs = self.packages.${system};
  };
  modules = [
    self.nixosModules.myModules
    ./hardware-configuration.nix
    ./configuration.nix
  ];
}
