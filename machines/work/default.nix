{ nixpkgs, inputs }: nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit nixpkgs inputs; };
  modules = [
    ./hardware-configuration.nix
    ./configuration.nix
    ../../modules/nogui.nix
  ];
}
