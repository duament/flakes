{ ... }:
{
  programs.fzf = {
    enable = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
  };

  programs.fish.interactiveShellInit = ''
    ${builtins.readFile ./fzf.fish}
  '';
}
