local ffi = require("ffi")

--SDL headers we use
ffi.cdef([[
	typedef struct SDL_Window SDL_Window;

	SDL_Window *SDL_GL_GetCurrentWindow(void);
	void SDL_SetWindowPosition(SDL_Window *window, int x, int y);
	void SDL_GetWindowPosition(SDL_Window *window, int *x, int *y);
]])

--PhysFS headers we use
ffi.cdef([[
	void PHYSFS_permitSymbolicLinks(int allow);
	int PHYSFS_symbolicLinksPermitted();
	int PHYSFS_isSymbolicLink(const char *fname);
]])

local liblove = (jit.os == "Windows" and ffi.load("love")) or ffi.C
local sdl = (jit.os == "Windows" and ffi.load("SDL2")) or ffi.C

if (love.graphics) then
	love.graphics.setNewFont(12)
end

--Window changes
if (love.window) then
	love.window.__setMode = love.window.setMode
	love.window.setMode = function(...)
		love.window.__setMode(...)
		love.event.push("resize", love.graphics.getDimensions())
	end

	love.window.setPosition = function(x, y)
		assert(type(x) == "number" and type(y) == "number", "love.window.setPosition accepts two parameters of type 'number'")
		sdl.SDL_SetWindowPosition(sdl.SDL_GL_GetCurrentWindow(), x, y)
	end

	love.window.getPosition = function()
		local x = ffi.new("int[1]")
		local y = ffi.new("int[1]")
		sdl.SDL_GetWindowPosition(sdl.SDL_GL_GetCurrentWindow(), x, y)

		return tonumber(x[0]), tonumber(y[0])
	end
end

--Filesystem changes
--Thanks to slime73 for the meat of this code
--Why wouldn't love.filesystem exist? Hell if I know.
if (love.filesystem) then
	love.filesystem.setSymbolicLinksEnabled = function(value)
		assert(type(value) == "boolean", "love.filesystem.setSymbolicLinksEnabled accepts one parameter of type 'boolean'")
		liblove.PHYSFS_permitSymbolicLinks(value and 1 or 0)
	end

	love.filesystem.getSymbolicLinksEnabled = function()
		return liblove.PHYSFS_symbolicLinksPermitted() ~= 0
	end

	love.filesystem.isSymbolicLink = function(path)
		assert(type(path) == "string", "love.filesystem.isSymbolicLink accepts one parameter of type 'string'")
		return liblove.PHYSFS_isSymbolicLink(path) ~= 0
	end
end