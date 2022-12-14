{ config, inputs, pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.python.enable = true;

  nix.package = pkgs.nix;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
    flake-registry = "${config.home.homeDirectory}/.config/nix/registry.json";
  };
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  home.username = "ruifeng.ma";
  home.homeDirectory = "/home/ruifeng.ma";

  home.packages = with pkgs; [
    abi-compliance-checker
    abi-dumper
    checksec
    #clang
    coreutils
    curl
    dig
    docker
    gcc
    gdb
    home-manager
    iproute2
    less
    openssl
    procps
    strace
    unar
    util-linux
  ];

  programs.fish.interactiveShellInit = ''
    if not set -q IN_NIX_SHELL
      fish_add_path -g /home/.devtools/tools/bin ~/.nix-profile/bin
    end
  '';

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
