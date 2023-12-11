{ config, lib, pkgs, ... }:
let
  fishVariablesFile = pkgs.writeText "fish_variables" ''
    # VERSION: 3.0
    SETUVAR fish_features:qmark\x2dnoglob
  '';
in
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      d = "docker";
      dl = "curl -LJO";
      gitad = "git add";
      gitap = "git apply";
      gitb = "git branch";
      gitcm = "git commit -m";
      gitcma = "git commit --amend";
      gitco = "git checkout";
      gitcob = "git checkout -b";
      gitcp = "git git-cherry-pick";
      gitdf = "git diff";
      gitdfs = "git diff --staged";
      gitf = "git fetch -p";
      giti = "git init -b main";
      gitib = "git init -b main --bare";
      gitl = "git log";
      gitls = "git log --show-signature";
      gitrs = "git reset";
      gitrsh = "git reset --hard";
      gitrt = "git restore";
      gitsh = "git show";
      gitsm = "git submodule";
      gitsmu = "git submodule update --init --recursive";
      gitss = "git stash";
      gitst = "git status";
      gitps = "git push";
      gitpsf = "git push -f";
      gitpsu = "git push -u origin HEAD";
      gitpl = "git pull";
      j = "journalctl";
      jb = "journalctl -b 0";
      jp = "journalctl -b 0 -p 4";
      mpvb = "mpv --ytdl-raw-options-append=cookies-from-browser=firefox::bilibili";
      nftadd = "sudo nft add inet nixos-fw input-allow tcp dport";
      nftls = "sudo nft -at list ruleset";
      nixrp = { expansion = "nix run nixpkgs#% --"; setCursor = true; position = "anywhere"; };
      nixsp = { expansion = "nix shell nixpkgs#% -c"; setCursor = true; position = "anywhere"; };
      r = "systemd-run --user -d -t --wait -G";
      s = "systemctl";
      se = "sudoedit";
      sls = "systemctl list-units --type=service";
      slt = "systemctl list-timers";
      suls = "systemctl --user list-units --type=service";
      sult = "systemctl --user list-timers";
      sus = "sudo systemctl";
      v = "nvim";
    } // (builtins.listToAttrs (builtins.genList
      (i:
        let
          n = toString (i + 1);
        in
        {
          name = "r${n}";
          value = "systemd-run --user -d -t --wait -G -u run-w${n}";
        }
      ) 9));
    shellAliases = {
      l = "eza -lag --time-style=long-iso";
      ll = "eza -lg --time-style=long-iso";
      lg = "eza -lag --git --time-style=long-iso";
      sl = "sudo eza -lag --time-style=long-iso";
    };
    interactiveShellInit = ''
      set fish_greeting

      if test $TERM != linux
        set fish_color_command brblue
        set fish_color_comment brblack
        set fish_color_end yellow
        set fish_color_escape red
        set fish_color_keyword cyan
        set fish_color_operator bryellow
        set fish_color_param magenta
        set fish_color_quote green
      end

      set -U fish_features qmark-noglob

      function gitdel
        set -l target
        if set -q argv[1]
          set target $argv[1]
        else
          set target develop
        end
        set -l branch (git rev-parse --abbrev-ref HEAD)
        git checkout $target
        git pull
        git branch -d $branch
        git push -d origin $branch
      end
    '';
  };

  home.activation.fishFeatureQmark = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f ${config.xdg.configHome}/fish/fish_variables ]; then
      install -Dm644 ${fishVariablesFile} ${config.xdg.configHome}/fish/fish_variables
    fi
  '';
}
