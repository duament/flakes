{
  source,
  buildPythonPackage,
  setuptools,
  ruamel-yaml,
  bullet,
  cjkwrap,
  typing-extensions,
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
    ruamel-yaml
    bullet
    cjkwrap
    typing-extensions
  ];

  meta = {
    description = "An extensible message tunneling chat bot framework.";
    homepage = "https://github.com/ehForwarderBot/ehForwarderBot";
    license = lib.licenses.agpl3Plus;
  };
}
