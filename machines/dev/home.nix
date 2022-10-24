{ pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.python.enable = true;

  home.username = "ruifeng.ma";
  home.homeDirectory = "/home/ruifeng.ma";

  home.packages = with pkgs; [
    abi-compliance-checker
    abi-dumper
    checksec
    #clang
    coreutils
    curl
    docker
    gcc
    gdb
    home-manager
    iproute2
    less
    ncdu
    openssl
    procps
    strace
    util-linux
  ];

  programs.git = {
    enable = true;
    userEmail = "int.ruifeng.ma@enflame-tech.com";
    userName = "ruifeng.ma";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  programs.starship.settings.command_timeout = 4000;
}
