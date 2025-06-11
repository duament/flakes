{
  source,
  stdenvNoCC,
  lib,
}:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  installPhase = ''
    mkdir -p $out/share
    cp -a $src $out/share/owntracks-frontend
  '';
  meta = {
    description = "Web interface for OwnTracks built with Vue.js";
    homepage = "https://github.com/owntracks/frontend";
    license = lib.licenses.mit;
  };
}
