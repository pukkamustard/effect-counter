# A simple counter as an Elm Effects Manager

> A.k.a. How you should not implement a counter in Elm, but how you might want to test an Effects Manager.

This implements a simple counter that increases on keyboard arrow up and down as Elm Effects Manager. The implementation is tested with [jsverify](https://github.com/jsverify/jsverify) and headless Chromium (using [puppeteer](https://github.com/GoogleChrome/puppeteer)).

The counter is a contrived example to explore how more complicated Effects Managers (e.g. handling of hardware connectivity) may be tested.

## Overview

The Effects Manager is implemented in [`src/Counter.elm`](src/Counter.elm). A simple Elm Application for running the tests is in [`test/Main.elm`](test/Main.elm). This application is compiled and served with `elm-reactor`. The test suite defined in [`test/index.js`](test/index.js) will start a headless Chromium instance, load the Elm application from the reactor and run test by simulating keyboard and mouse events.


## Quick start

- Install dependencies: `npm install` (or `nix-shell` - this might cause Chromium to be compiled, which will take a while)
- Start the elm reactor: `elm reactor`
- Run the test: `npm test`


## Known limitations

- Using `elm-reactor` is very inefficient as the test application is recompiled every time it is loaded. Compiling once and serving the output would be enough.
- A way to figure out when coputations are completed (or a subscription value is changed) would be nice instead of waiting for a fixed time for computations to complete. This should be possible with [`waitFor` commands](https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagewaitforselectororfunctionortimeout-options-args).
