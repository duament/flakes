{ stdenvNoCC, lib, writeText }:
let
  themeConf = writeText "theme.conf" ''
    [Metadata]
    Name=my-theme
    Version=0.0.1
    Author=Rvfg
    Description=My theme

    [InputPanel]
    NormalColor=#000000
    HighlightCandidateColor=#000000
    HighlightColor=#000000
    HighlightBackgroundColor=#eceff4

    [InputPanel/Background]
    Color=#e4f1ff

    [InputPanel/Background/Margin]
    Left=2
    Right=2
    Top=2
    Bottom=2

    [InputPanel/Highlight]
    Color=#f9d8f0

    [InputPanel/Highlight/Margin]
    Left=10
    Right=10
    Top=7
    Bottom=7

    [InputPanel/TextMargin]
    Left=10
    Right=10
    Top=6
    Bottom=6
  '';
in
stdenvNoCC.mkDerivation {
  pname = "fcitx5-theme";
  version = "0.0.1";
  src = themeConf;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/share/fcitx5/themes/my-theme
    install -Dm644 $src $out/share/fcitx5/themes/my-theme/theme.conf
  '';
  meta = {
    description = "My fcitx5 theme";
    homepage = "";
    license = lib.licenses.mit;
  };
}
