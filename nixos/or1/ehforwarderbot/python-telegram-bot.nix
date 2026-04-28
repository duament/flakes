{
  lib,
  apscheduler,
  buildPythonPackage,
  setuptools,
  cachetools,
  certifi,
  decorator,
  fetchFromGitHub,
  tornado,
  urllib3,
  pytz,
  standard-imghdr,
}:

buildPythonPackage rec {
  pname = "python-telegram-bot";
  version = "13.15";

  pyproject = true;
  build-system = [
    setuptools
  ];

  src = fetchFromGitHub {
    owner = "python-telegram-bot";
    repo = "python-telegram-bot";
    tag = "v13.15";
    hash = "sha256-EViSjr/nnuJIDTwV8j/O50hJkWV3M5aTNnWyzrinoyg=";
  };

  patches = [
    ./python-telegram-bot-no-appengine.patch
  ];

  dependencies = [
    setuptools
    apscheduler
    cachetools
    certifi
    decorator
    tornado
    urllib3
    pytz
    standard-imghdr
  ];

  # --with-upstream-urllib3 is not working properly
  postPatch = ''
    rm -r telegram/vendor

    substituteInPlace requirements.txt \
      --replace "APScheduler==3.6.3" "APScheduler" \
      --replace "cachetools==4.2.2" "cachetools" \
      --replace "tornado==6.1" "tornado"

    substituteInPlace setup.py \
      --replace "version=locals()['__version__']" "version='${version}'"
  '';

  setupPyGlobalFlags = [ "--with-upstream-urllib3" ];

  pythonImportsCheck = [
    "telegram"
  ];

  meta = with lib; {
    description = "Python library to interface with the Telegram Bot API";
    homepage = "https://python-telegram-bot.org";
    license = licenses.lgpl3Only;
  };
}
