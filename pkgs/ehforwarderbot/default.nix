{ source, buildPythonPackage, lib }:
buildPythonPackage {
  inherit (source) pname version src;

  meta = with lib; {
    description = "An extensible message tunneling chat bot framework. Delivers messages to and from multiple platforms and remotely control your accounts.";
    homepage = "https://github.com/ehForwarderBot/ehForwarderBot";
    license = licenses.agpl3Plus;
  };
}
