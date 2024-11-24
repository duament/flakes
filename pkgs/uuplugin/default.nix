{ sources, stdenvNoCC }:
let
  source = sources."uuplugin-${stdenvNoCC.hostPlatform.parsed.cpu.name}";
in
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  unpackPhase = ''
    tar xf $src
  '';
  installPhase = ''
    install -Dm755 uuplugin $out/bin/uuplugin
    install -Dm644 uu.conf $out/share/uuplugin/uu.conf
  '';
  meta = {
    description = "uuplugin";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
