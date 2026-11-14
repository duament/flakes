{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "autoindex-viewer";
  version = "0.1.0";
  src = ./src;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/share
    cp -a $src $out/share/autoindex-viewer
  '';
  meta = {
    description = "A dependency-free SPA that renders nginx's `autoindex_format json` output as a minimal file browser.";
  };
}
