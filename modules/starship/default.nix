{ lib, ... }:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableIonIntegration = false;
    enableZshIntegration = false;
    settings = {
      format = lib.concatStrings [
        "$container"
        "$all"
        "$line_break"
        "$character"
      ];
      container = {
        style = "bold yellow dimmed";
        format = "[$symbol $name ]($style)";
      };
      directory = {
        truncation_length = 5;
        fish_style_pwd_dir_length = 1;
      };
      git_branch = {
        style = "green";
        symbol = "";
      };
      git_status = {
        behind = "[⇣$count](green) ";
        ahead = "[⇡$count](green) ";
        stashed = "[*$count](green) ";
        modified = "[!$count](yellow) ";
        renamed = "[»$count](yellow) ";
        deleted = "[✘$count](yellow) ";
        staged = "[+$count](yellow) ";
        untracked = "[?$count](blue) ";
        conflicted = "[~$count](red) ";
        diverged = "[⇕$count](red) ";
        format = "([$all_status$ahead_behind]($style))";
      };
      hostname = {
        ssh_symbol = "";
      };
      package = {
        symbol = "";
      };
      status = {
        disabled = false;
        symbol = "✗";
      };
      cmake = {
        version_format = "";
        symbol = "CMake ";
      };
      cobol = {
        version_format = "";
        symbol = "COBOL ";
      };
      conda = {
        symbol = "Conda ";
      };
      crystal = {
        version_format = "";
        symbol = "Crystal ";
      };
      dart = {
        version_format = "";
        symbol = "Dart ";
      };
      deno = {
        version_format = "";
        symbol = "Deno ";
      };
      docker_context = {
        symbol = "Docker ";
      };
      dotnet = {
        version_format = "";
        symbol = ".NET ";
      };
      elixir = {
        version_format = "";
        symbol = "Elixir ";
      };
      elm = {
        version_format = "";
        symbol = "Elm ";
      };
      erlang = {
        version_format = "";
        symbol = "Erlang ";
      };
      golang = {
        version_format = "";
        symbol = "Go ";
      };
      helm = {
        version_format = "";
        symbol = "Helm ";
      };
      java = {
        version_format = "";
        symbol = "Java ";
      };
      julia = {
        version_format = "";
        symbol = "Julia ";
      };
      kotlin = {
        version_format = "";
        symbol = "Kotlin ";
      };
      lua = {
        version_format = "";
        symbol = "Lua ";
      };
      nim = {
        version_format = "";
        symbol = "Nim ";
      };
      nix_shell = {
        symbol = "nix-shell ";
      };
      nodejs = {
        version_format = "";
        symbol = "Node.js ";
      };
      ocaml = {
        version_format = "";
        symbol = "OCaml ";
      };
      perl = {
        version_format = "";
        symbol = "Perl ";
      };
      php = {
        version_format = "";
        symbol = "PHP ";
      };
      purescript = {
        version_format = "";
        symbol = "PureScript ";
      };
      python = {
        version_format = "";
        symbol = "Python ";
      };
      rlang = {
        version_format = "";
        symbol = "R ";
      };
      red = {
        version_format = "";
        symbol = "Red ";
      };
      ruby = {
        version_format = "";
        symbol = "Ruby ";
      };
      rust = {
        version_format = "";
        symbol = "Rust ";
      };
      scala = {
        version_format = "";
        symbol = "Scala ";
      };
      swift = {
        version_format = "";
        symbol = "Swift ";
      };
      vagrant = {
        version_format = "";
        symbol = "Vagrant ";
      };
      vlang = {
        version_format = "";
        symbol = "V ";
      };
      zig = {
        version_format = "";
        symbol = "Zig ";
      };
    };
  };

  programs.fish.interactiveShellInit = ''
    ${builtins.readFile ./starship_async_transient_prompt.fish}
  '';
}
