{ self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.neovim.enableLsp = false;
}
