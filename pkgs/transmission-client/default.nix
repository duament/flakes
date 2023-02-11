{ source, mkYarnPackage, lib }:
mkYarnPackage {
  inherit (source) pname version src;
  patchPhase = ''
    sed -i 's/"homepage": "[^"]*"/"homepage": "."/g' package.json
    sed -i 's|/transmission/rpc|../rpc|g' src/setupProxy.js
    sed -i 's|/transmission/rpc|../rpc|g' src/api/request.ts
  '';
  postConfigure = with source; ''
    REAL_PATH=$(readlink -f "deps/${pname}/node_modules")
    rm -f "deps/${pname}/node_modules"
    cp -r "$REAL_PATH" "deps/${pname}/node_modules"
    chmod -R +w "deps/${pname}/node_modules"
  '';
  buildPhase = ''
    export HOME=$(mktemp -d)
    export NODE_OPTIONS=--openssl-legacy-provider
    export REACT_APP_MUIX_LICENSE_KEY=ca15e5b68b66fc9813877228ab994c77T1JERVI6eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHgsRVhQSVJZPTE4OTYxMDU2MDAwMDAsS0VZVkVSU0lPTj0x
    yarn --offline build
  '';
  installPhase = ''
    mkdir -p $out/share
    cp -a deps/${source.pname}/build $out/share/transmission-client
  '';
  distPhase = "true";
  meta = {
    description = "A modern web client for Transmission, built with React, Material-UI and Typescript.";
    homepage = "https://github.com/zj9495/transmission-client";
    license = lib.licenses.mit;
  };
}
