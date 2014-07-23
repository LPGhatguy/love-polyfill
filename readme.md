# LOVE Shim
This is a project that provides a couple (potentially) useful changes to LOVE in the hopes of assisting developers that might be using the framework. To use it, just call `require("love-shim")` after LOVE has been loaded.

## Current Features
- Provides a default font object so that love.graphics.getFont won't fizzle.
- Makes love.window.setMode fire a "resize" event
- Adds love.window.setPosition and love.window.getPosition to set/get window positions
- Adds love.filesystem.setSymbolicLinksEnabled, love.filesystem.getSymbolicLinksEnabled, and love.filesystem.isSymbolicLink for symbolic link manipulation.