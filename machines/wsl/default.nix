{ inputs, nixpkgs, self }: nixpkgs.lib.nixosSystem rec {
  system = "x86_64-linux";
  specialArgs = {
    inherit inputs self;
    mypkgs = self.packages.${system};
  };
  modules = [
    self.nixosModules.myModules
    inputs.wsl.nixosModules.wsl
    ./configuration.nix
  ];
}
