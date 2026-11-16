{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm,
  pnpmConfigHook,
  pnpmBuildHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "transmission-next-ui";
  version = "0.3.4";
  src = fetchFromGitHub {
    owner = "hisproc";
    repo = "transmission-next-ui";
    rev = "v${finalAttrs.version}";
    hash = "sha256-kYZyZlXuKx8QOh+r8z0cEBqf28MERMkg6IvjhbeL6yk=";
  };

  patches = [
    ./no-update-check.patch
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 5;
    hash = "sha256-0+ditdYt0PJ88TUawZw6Z5y0zYVT1SKWwbToyH4fBxA=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpmBuildHook
    pnpm
  ];

  installPhase = ''
    mkdir -p $out/share
    cp -a dist $out/share/transmission-next-ui
  '';

  meta = {
    description = "A modern web-based frontend for Transmission, offering a sleek and responsive UI for managing your torrents with ease, built using shadcn/ui and Vite.";
    homepage = "https://github.com/hisproc/transmission-next-ui";
    license = lib.licenses.mit;
  };
})
