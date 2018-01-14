with import <nixpkgs> {};

stdenv.mkDerivation {
    name = "effect-counter";
    builder = "${bash}/bin/bash";
    buildInputs = [
      elmPackages.elm
      nodejs-8_x
      chromiumDev
    ];

    shellHook = ''
      # prevent puppeteer from installing a bundled chromium
      export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
      export CHROMIUM_PATH=${chromiumDev}/bin/chromium

      npm install
    '';
}

