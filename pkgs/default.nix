pkgs:
let
  mapPackages = f: with builtins;listToAttrs (map (name: { inherit name; value = f name; }) (filter (v: v != null) (attrValues (mapAttrs (k: v: if v == "directory" && k != "_sources" then k else null) (readDir ./.)))));
in
mapPackages (name:
let
  sources = pkgs.callPackage ./_sources/generated.nix { };
  package = import ./${name};
  args = builtins.intersectAttrs (builtins.functionArgs package) {
    inherit sources;
    source = sources.${name};
  };
in
pkgs.callPackage package args
)
