{ source, rustPlatform, lib }:
rustPlatform.buildRustPackage {
  inherit (source) pname version src;
  cargoLock = source.cargoLock."Cargo.lock";

  meta = {
    description = "";
    homepage = "https://github.com/duament/uutunnel";
    license = lib.licenses.mit;
  };
}
