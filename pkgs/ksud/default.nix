{ source, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  dontUnpack = true;
  installPhase = ''
    install -Dm755 $src $out/bin/ksud
  '';
  meta = {
    description = "A Kernel based root solution for Android";
    platforms = [
      "x86_64-linux"
    ];
  };
}
