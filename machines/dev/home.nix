{ pkgs, ... }:
let
  my-python-packages = python-packages: with python-packages; [
    ipython
    requests
  ]; 
  python-with-my-packages = pkgs.python3.withPackages my-python-packages;
in {
  imports = [
    ../../modules/common-home.nix
  ];

  home.username = "rvfg";
  home.homeDirectory = "/home/rvfg";

  home.packages = with pkgs; [
    checksec
    #clang
    coreutils
    curl
    docker
    gcc
    gdb
    home-manager
    iproute2
    jq
    less
    ncdu
    openssl
    procps
    python-with-my-packages
    strace
    util-linux
  ];

  programs.fish.shellInit = ''
    set -gx EDITOR neovim
    set -gx VISUAL neovim
  '';

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
