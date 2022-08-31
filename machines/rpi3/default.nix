{ nixpkgs, inputs }: nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  specialArgs = { inherit nixpkgs inputs; };
  modules = [
    ./hardware-configuration.nix
    ./configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
  ];
}
