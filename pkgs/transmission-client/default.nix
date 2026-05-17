{
  source,
  lib,
  stdenv,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
}:
let
  inherit (builtins) fromJSON readFile;

  hash = fromJSON (readFile ./hash.json);
in
stdenv.mkDerivation (finalAttrs: {
  inherit (source) pname version src;

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = hash.yarnOfflineCache;
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    nodejs
  ];

  postPatch = ''
    sed -i 's/"homepage": "[^"]*"/"homepage": "."/g' package.json
    sed -i 's|/transmission/rpc|../rpc|g' src/setupProxy.js
    sed -i 's|/transmission/rpc|../rpc|g' src/api/request.ts
  '';

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    export NODE_OPTIONS=--openssl-legacy-provider
    export REACT_APP_MUIX_LICENSE_KEY=ca15e5b68b66fc9813877228ab994c77T1JERVI6eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHgsRVhQSVJZPTE4OTYxMDU2MDAwMDAsS0VZVkVSU0lPTj0x
    yarn --offline build

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/share
    cp -a build $out/share/transmission-client
  '';
  distPhase = "true";

  meta = {
    description = "A modern web client for Transmission, built with React, Material-UI and Typescript.";
    homepage = "https://github.com/zj9495/transmission-client";
    license = lib.licenses.mit;
  };
})
