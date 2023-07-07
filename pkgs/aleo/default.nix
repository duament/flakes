{ source, stdenvNoCC, lib }:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp -a $src/fonts/variable/*.ttf $out/share/fonts/truetype

    runHook postInstall
  '';
  meta = {
    description = "Aleo font family";
    homepage = "https://github.com/AlessioLaiso/aleo";
    license = lib.licenses.ofl;
  };
}
