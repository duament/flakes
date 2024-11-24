{
  source,
  stdenvNoCC,
  lib,
}:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  installPhase = ''
    mkdir -p $out/share
    cp -a $src $out/share/flood-for-transmission
  '';
  meta = {
    description = "A Flood (https://github.com/Flood-UI/flood) clone for Transmission";
    homepage = "https://github.com/johman10/flood-for-transmission";
    license = lib.licenses.gpl3;
  };
}
