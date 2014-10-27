# LÖVE Polyfill
This is a project that provides select features from future versions of LÖVE for versions that are released now. This lets developers target existing versions while still developing for near-future versions of LÖVE.

Run `require("love-polyfill")` after LÖVE has been loaded.

## Current Additions
See the LÖVE wiki for details on these methods.
- love.window.setPosition, love.window.getPosition
- love.window.maximize, love.window.minimize
- love.window.showMessageBox
- love.filesystem.setSymlinksEnabled, love.filesystem.areSymlinksEnabled, love.filesystem.isSymlink