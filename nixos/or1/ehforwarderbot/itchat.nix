{
  source,
  buildPythonPackage,
  setuptools,
  requests,
  pyqrcode,
  pypng,
  lib,
}:
buildPythonPackage {
  inherit (source) pname version src;

  pyproject = true;
  build-system = [
    setuptools
  ];

  dependencies = [
    setuptools
    requests
    pyqrcode
    pypng
  ];

  meta = {
    description = "A complete and graceful API for Wechat.";
    homepage = "https://github.com/littlecodersh/ItChat";
    license = lib.licenses.mit;
  };
}
