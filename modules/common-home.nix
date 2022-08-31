{ ... }:
{
  imports = [
    ../../modules/fish.nix
    ../../modules/fzf
    ../../modules/neovim
    ../../modules/starship
  ];

  programs.exa.enable = true;

  programs.htop = {
    enable = true;
    settings = {
      hide_userland_threads = 1;
      detailed_cpu_time = 1;
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
