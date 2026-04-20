{
  source,
  rustPlatform,
  lib,
}:
rustPlatform.buildRustPackage {
  inherit (source) pname version src;
  cargoLock = source.cargoLock."Cargo.lock";
  buildAndTestSubdir = "userspace/ksud";

  meta = {
    description = "A Kernel based root solution for Android";
    homepage = "https://kernelsu.org/";
    license = lib.licenses.gpl3Plus;
  };
}
