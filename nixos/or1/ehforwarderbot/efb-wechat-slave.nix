{
  lib,
  source,
  buildPythonPackage,
  setuptools,
  ehforwarderbot,
  python-magic,
  pillow,
  pyqrcode,
  pypng,
  pyyaml,
  requests,
  typing-extensions,
  bullet,
  cjkwrap,
}:
buildPythonPackage {
  inherit (source) pname version src;

  pyproject = true;
  build-system = [
    setuptools
  ];

  dependencies = [
    setuptools
    ehforwarderbot
    python-magic
    requests
    pillow
    pyqrcode
    pypng
    pyyaml
    bullet
    cjkwrap
    typing-extensions
  ];

  meta = {
    description = "WeChat Slave Channel for EH Forwarder Bot, based on WeChat Web API.";
    homepage = "https://github.com/ehForwarderBot/efb-wechat-slave";
    license = lib.licenses.agpl3Plus;
  };
}
