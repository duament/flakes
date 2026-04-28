{
  lib,
  source,
  buildPythonPackage,
  setuptools,
  ehforwarderbot,
  python-telegram-bot,
  python-magic,
  ffmpeg-python,
  peewee,
  requests,
  pydub,
  ruamel-yaml,
  pillow,
  language-tags,
  retrying,
  bullet,
  cjkwrap,
  humanize,
  typing-extensions,
  lottie,
  cairosvg,
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
    python-telegram-bot
    python-magic
    ffmpeg-python
    peewee
    requests
    pydub
    ruamel-yaml
    pillow
    language-tags
    retrying
    bullet
    cjkwrap
    humanize
    typing-extensions
    lottie
    cairosvg
  ];

  meta = {
    description = "Telegram Master Channel for EH Forwarder Bot, based on Telegram Bot API.";
    homepage = "https://github.com/ehForwarderBot/efb-telegram-master";
    license = lib.licenses.agpl3Plus;
  };
}
