{
  source,
  stdenvNoCC,
  lib,
}:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  installPhase = ''
    mkdir -p $out/share
    cp -a $src/Nginx-Fancyindex $out/share/Nginx-Fancyindex
  '';
  meta = {
    description = "A responsive theme for Nginx Fancyindex module.";
    homepage = "https://github.com/Naereen/Nginx-Fancyindex-Theme";
    license = lib.licenses.mit;
  };
}
