{ sources, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  inherit (sources.magisk) version src;
  pname = "magiskboot";
  installPhase = ''
    install -Dm755 lib/${stdenvNoCC.hostPlatform.parsed.cpu.name}/libmagiskboot.so $out/bin/magiskboot
  '';
  meta = {
    description = "The Magic Mask for Android (extracted magiskboot binary)";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
