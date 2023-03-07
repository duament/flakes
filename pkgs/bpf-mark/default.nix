{ clangStdenv
, lib
, libbpf
, markValue ? 1
, runCommandWith
, writeScript
}:
clangStdenv.mkDerivation {
  pname = "bpf-mark-${toString markValue}";
  version = "1.0";
  src = ./bpf-mark.c;
  dontUnpack = true;
  nativeBuildInputs = [ libbpf ];

  configurePhase = ''
    export markValue=${toString markValue}
    substituteAll $src bpf-mark.c
  '';

  buildPhase = ''
    clang -O2 -target bpf -c bpf-mark.c -o bpf-mark.o 
  '';

  installPhase = ''
    install -Dm644 bpf-mark.o $out
  '';

  meta = {
    license = lib.licenses.gpl3;
  };
}
