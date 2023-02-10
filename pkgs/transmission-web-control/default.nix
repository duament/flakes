{ source, stdenvNoCC, lib }:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  installPhase = ''
    mkdir -p $out/share
    cp -a $src/src $out/share/transmission-web-control
  '';
  postFixup = ''
    sed -i 's/theme: "default",/theme: "metro",/g' $out/share/transmission-web-control/tr-web-control/config.js
  '';
  meta = {
    description = "Transmission Web Control is a custom web UI.";
    homepage = "https://github.com/ronggang/transmission-web-control";
    license = lib.licenses.mit;
  };
}
