# LÖVE Polyfill
This is a project that provides select features from future versions of LÖVE for versions that are released now. This lets developers target existing versions while still developing for near-future versions of LÖVE.

Presently, LÖVE Polyfill targets LÖVE 0.9.2, implementing fixes and features from a hypothetical 0.9.3.

Run `require("love-polyfill")` after LÖVE has been loaded.

## Current Changes
- Added love.window.maximize
- Fixed love.keyboard.getKeyFromScancode to not crash on invalid scancodes
- Fixed love.graphics.getColorMask to return proper state