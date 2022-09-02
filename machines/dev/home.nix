{ pkgs, ... }:
let
  my-python-packages = python-packages: with python-packages; [
    ipython
    requests
  ]; 
  python-with-my-packages = python3.withPackages my-python-packages;
in {
  imports = [
    ../../modules/common-home.nix
  ];

  home.packages = with pkgs; [
    checksec
    #clang
    gcc
    gdb
    ncdu
    python-with-my-packages
  ];

  programs.git = {
    enable = true;
    userEmail = "int.ruifeng.ma@enflame-tech.com";
    userName = "ruifeng.ma";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  home.stateVersion = "22.11";
}
