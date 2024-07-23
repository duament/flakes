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
    nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
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
    openssh
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
    userEmail = "ruifeng.ma@enflame-tech.com";
    userName = "ruifeng.ma";
    signing = {
      signByDefault = true;
      key = "~/.ssh/id_ed25519";
    };
    extraConfig = {
      init.defaultBranch = "main";
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = (pkgs.writeText "allowed_signers" ''
        int.ruifeng.ma@enflame-tech.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkJYJCkj7fPff31pDkGULXhgff+jaaj4BKu1xzL/DeZ
      '').outPath;
    };
    delta = {
      enable = true;
      options = {
        light = true;
        line-numbers = true;
        side-by-side = true;
      };
    };
  };

  programs.starship.settings.command_timeout = 4000;
}
