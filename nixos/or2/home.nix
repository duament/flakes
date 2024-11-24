{ self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];
}
