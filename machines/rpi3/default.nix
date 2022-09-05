{ nixpkgs, inputs }: nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  specialArgs = { inherit nixpkgs inputs; };
  modules = [
    ./hardware-configuration.nix
    ./configuration.nix
    ../../modules/nogui.nix
  ];
}
