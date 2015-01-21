--love-polyfill version 1.1.3
--Implements 0.9.2 features into 0.9.1
--Lucien Greathouse (LPGhatguy)

local ffi = require("ffi")
local bit = require("bit")

--SDL headers we use
ffi.cdef([[
	typedef enum {
		SDL_MESSAGEBOX_ERROR = 0x00000010,
		SDL_MESSAGEBOX_WARNING = 0x00000020,
		SDL_MESSAGEBOX_INFORMATION = 0x00000040
	} SDL_MessageBoxFlags;

	typedef enum {
		SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT = 0x00000001,
		SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT = 0x00000002
	} SDL_MessageBoxButtonFlags;

	typedef enum {
		SDL_WINDOW_FULLSCREEN = 0x00000001,
		SDL_WINDOW_OPENGL = 0x00000002,
		SDL_WINDOW_SHOWN = 0x00000004,
		SDL_WINDOW_HIDDEN = 0x00000008,
		SDL_WINDOW_BORDERLESS = 0x00000010,
		SDL_WINDOW_RESIZABLE = 0x00000020,
		SDL_WINDOW_MINIMIZED = 0x00000040,
		SDL_WINDOW_MAXIMIZED = 0x00000080,
		SDL_WINDOW_INPUT_GRABBED = 0x00000100,
		SDL_WINDOW_INPUT_FOCUS = 0x00000200,
		SDL_WINDOW_MOUSE_FOCUS = 0x00000400,
		SDL_WINDOW_FULLSCREEN_DESKTOP = ( SDL_WINDOW_FULLSCREEN | 0x00001000 ),
		SDL_WINDOW_FOREIGN = 0x00000800,
		SDL_WINDOW_ALLOW_HIGHDPI = 0x00002000
	} SDL_WindowFlags;

	typedef struct SDL_Window SDL_Window;

	typedef struct {
		uint32_t flags;
		int buttonid;
		const char *text;
	} SDL_MessageBoxButtonData;

	typedef struct {
		uint8_t r, g, b;
	} SDL_MessageBoxColor;

	typedef struct {
		SDL_MessageBoxColor colors[5];
	} SDL_MessageBoxColorScheme;

	typedef struct {
		uint32_t flags;
		SDL_Window *window;
		const char *title;
		const char *message;
		int numbuttons;
		const SDL_MessageBoxButtonData *buttons;
		const SDL_MessageBoxColorScheme *colorScheme;
	} SDL_MessageBoxData;

	typedef struct {
		int x, y, w, h;
	} SDL_Rect;

	SDL_Window *SDL_GL_GetCurrentWindow(void);
	void SDL_SetWindowPosition(SDL_Window *window, int x, int y);
	void SDL_GetWindowPosition(SDL_Window *window, int *x, int *y);
	void SDL_MaximizeWindow(SDL_Window *window);
	void SDL_MinimizeWindow(SDL_Window *window);
	int SDL_ShowSimpleMessageBox(uint32_t flags, const char *title, const char *message, SDL_Window *window);
	int SDL_ShowMessageBox(const SDL_MessageBoxData *messageboxdata, int *buttonid);
	int SDL_GetNumVideoDisplays();
	int SDL_GetDisplayBounds(int display, SDL_Rect *rect);
	int SDL_GetWindowDisplayIndex(SDL_Window *window);
	int SDL_GetWindowFlags(SDL_Window *window);
]])

--PhysFS headers we use
ffi.cdef([[
	void PHYSFS_permitSymbolicLinks(int allow);
	int PHYSFS_symbolicLinksPermitted();
	int PHYSFS_isSymbolicLink(const char *fname);
]])

local liblove = (ffi.os == "Windows") and ffi.load("love") or ffi.C
local sdl = (ffi.os == "Windows") and ffi.load("SDL2") or ffi.C

if (not love) then
	error("love-polyfill requires love to be loaded and in the global namespace")
end

if (love.polyfill) then
	return print("Skipping love-polyfill load, polyfill already loaded")
end

love.polyfill = {
	version = {1, 1, 3},
	versionCode = 5,
	emulating = "0.9.2"
}

--Window changes
if (love.window) then
	love.window.setPosition = love.window.setPosition or function(x, y, display)
		local displayCount = tonumber(sdl.SDL_GetNumVideoDisplays());
		display = math.min(math.max(display and display - 1 or 0, 0), displayCount - 1)

		local p_displayBounds = ffi.new("SDL_Rect[1]")
		sdl.SDL_GetDisplayBounds(display, p_displayBounds)

		x = x + p_displayBounds[0].x
		y = y + p_displayBounds[0].y

		sdl.SDL_SetWindowPosition(sdl.SDL_GL_GetCurrentWindow(), x, y)
	end

	love.window.getPosition = love.window.getPosition or function()
		local window = sdl.SDL_GL_GetCurrentWindow()
		local x = ffi.new("int[1]")
		local y = ffi.new("int[1]")
		sdl.SDL_GetWindowPosition(window, x, y)

		local display = math.max(tonumber(sdl.SDL_GetWindowDisplayIndex(window)), 0)

		if (bit.band(sdl.SDL_GetWindowFlags(window), sdl.SDL_WINDOW_FULLSCREEN) == 0) then
			local p_displayBounds = ffi.new("SDL_Rect[1]")
			sdl.SDL_GetDisplayBounds(display, p_displayBounds)

			x[0] = x[0] - p_displayBounds[0].x
			y[0] = y[0] - p_displayBounds[0].y
		end

		return tonumber(x[0]), tonumber(y[0]), display + 1
	end

	love.window.minimize = love.window.minimize or function()
		sdl.SDL_MinimizeWindow(sdl.SDL_GL_GetCurrentWindow());
	end

	love.window.maximize = love.window.maximize or function()
		sdl.SDL_MaximizeWindow(sdl.SDL_GL_GetCurrentWindow());
	end

	local messageboxtypemap = {
		info = sdl.SDL_MESSAGEBOX_INFORMATION,
		warning = sdl.SDL_MESSAGEBOX_WARNING,
		error = sdl.SDL_MESSAGEBOX_ERROR
	}

	love.window.showMessageBox = love.window.showMessageBox or function(title, message, ...)
		if (type((...)) == "table") then
			-- title, message, buttonlist, type, attach
			local buttonlist = select(1, ...)
			local boxtype = select(2, ...) or "info"
			local attach = select(3, ...)

			local mapped = messageboxtypemap[boxtype]
			assert(mapped, "Invalid MessageBox type '" .. tostring(boxtype) .. "'")

			local window
			if (attach or attach == nil) then
				window = sdl.SDL_GL_GetCurrentWindow()
			end

			local numbuttons = #buttonlist
			local buttons = {}

			for i = 1, numbuttons do
				local button = {0, i, buttonlist[i]}

				if (buttonlist["enter"]) then
					button[1] = sdl.SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT
				elseif (buttonlist["escape"]) then
					button[2] = sdl.SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT
				end

				table.insert(buttons, button)
			end

			local p_boxdata = ffi.new("SDL_MessageBoxData[1]", {{
				mapped,
				window,
				title,
				message,
				numbuttons,
				ffi.new("SDL_MessageBoxButtonData[?]", numbuttons, buttons),
				nil
			}})

			local p_buttonid = ffi.new("int[1]")
			if (sdl.SDL_ShowMessageBox(p_boxdata, p_buttonid) < 0) then
				return -1
			end

			return tonumber(p_buttonid[0])
		else
			-- title, message, type, attach
			local boxtype = select(1, ...) or "info"
			local attach = select(2, ...)

			local mapped = messageboxtypemap[boxtype]
			assert(mapped, "Invalid MessageBox type '" .. tostring(boxtype) .. "'")

			local window
			if (attach or attach == nil) then
				window = sdl.SDL_GL_GetCurrentWindow()
			end

			return sdl.SDL_ShowSimpleMessageBox(messageboxtypemap[boxtype], title, message, window) == 0
		end
	end
end

if (love.filesystem) then
	love.filesystem.setSymlinksEnabled = love.filesystem.setSymlinksEnabled or function(value)
		assert(type(value) == "boolean", "love.filesystem.setSymlinksEnabled accepts one parameter of type 'boolean'")
		liblove.PHYSFS_permitSymbolicLinks(value and 1 or 0)
	end

	love.filesystem.areSymlinksEnabled = love.filesystem.areSymlinksEnabled or function()
		return liblove.PHYSFS_symbolicLinksPermitted() ~= 0
	end

	love.filesystem.isSymlink = love.filesystem.isSymlink or function(path)
		assert(type(path) == "string", "love.filesystem.isSymlink accepts one parameter of type 'string'")
		return liblove.PHYSFS_isSymbolicLink(path) ~= 0
	end
end