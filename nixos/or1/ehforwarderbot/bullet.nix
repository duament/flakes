{
  source,
  buildPythonPackage,
  setuptools,
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
  ];

  meta = {
    description = "Beautiful Python Prompts Made Simple";
    homepage = "https://github.com/bchao1/bullet";
    license = lib.licenses.mit;
  };
}
