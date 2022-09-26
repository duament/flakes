{ pkgs, ... }:
let
  my-python-packages = python-packages: with python-packages; [
    ipython
    requests
  ];
  python-with-my-packages = pkgs.python3.withPackages my-python-packages;
in {
  imports = [
    ../../home-modules/common.nix
  ];

  home.username = "ruifeng.ma";
  home.homeDirectory = "/home/ruifeng.ma";

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
