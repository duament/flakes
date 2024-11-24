{
  source,
  rustPlatform,
  lib,
  pkg-config,
  bzip2,
  xz,
}:
rustPlatform.buildRustPackage {
  inherit (source) pname version src;
  cargoLock = source.cargoLock."Cargo.lock";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    bzip2
    xz
  ];

  meta = {
    description = "Sign (and root) Android A/B OTAs with custom keys while preserving Android Verified Boot";
    homepage = "https://github.com/chenxiaolong/avbroot";
    license = lib.licenses.gpl3;
  };
}
