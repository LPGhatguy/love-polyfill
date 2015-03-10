--love-polyfill version 1.2.0
--Implements 0.9.3 features and bugfixes into 0.9.2
--Lucien Greathouse (LPGhatguy)

local ffi = require("ffi")

--SDL headers we use
ffi.cdef([[
	typedef struct SDL_Window SDL_Window;

	SDL_Window *SDL_GL_GetCurrentWindow(void);
	void SDL_MaximizeWindow(SDL_Window *window);
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
	error("love-polyfill requires love to be loaded and in the global namespace", 2)
end

if (love.polyfill_0_9_3) then
	return print("Skipping love-polyfill 0.9.3 load, 0.9.3 polyfill already loaded")
end

love.polyfill_0_9_3 = true
love.polyfill = {
	version = {1, 2, 0},
	versionCode = 6,
	target = "0.9.2",
	emulating = "0.9.3"
}

--Window additions
if (love.window) then
	-- 0.9.2 was supposed to ship with this, but didn't.
	love.window.maximize = love.window.maximize or function()
		sdl.SDL_MaximizeWindow(sdl.SDL_GL_GetCurrentWindow())
	end
end

-- 0.9.2 has a couple broken methods
if (love.graphics) then
	-- Bugfix: 0.9.x's getColorMask doesn't return the correct state
	local setcm = love.graphics.setColorMask
	local valuecm = {true, true, true, true}

	function love.graphics.getColorMask()
		return valuecm[1], valuecm[2], valuecm[3], valuecm[4]
	end

	function love.graphics.setColorMask(r, g, b, a)
		valuecm[1] = r
		valuecm[2] = g
		valuecm[3] = b
		valuecm[4] = a
		setcm(r, g, b, a)
	end
end

if (love._version_revision == 2 and love.keyboard) then
	--Bugfix: 0.9.2's getKeyFromScancode crashes on invalid scancodes
	local scancode_list = {
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
		"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
		"capslock", "return", "escape", "backspace", "tab", "space",
		"-", "=", "[", "]", "\\", "nonus#", ";", "'", "`", ",", ".", "/", "=",
		"f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
		"f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f34",
		"printscreen", "scrolllock", "pause", "sysreq",
		"insert", "home", "pageup", "delete", "end", "pagedown",
		"right", "left", "down", "up",
		"numlock", "kp/", "kp*", "kp-", "kp+", "kpenter",
		"kp1", "kp2", "kp3", "kp4", "kp5", "kp6", "kp7", "kp8", "kp9", "kp0", "kp.",
		"kp00", "kp000", "kp(", "kp)", "kp{", "kp}", "kptab", "kpbackspace",
		"kpa", "kpb", "kpc", "kpd", "kpe", "kpf",
		"kpxor", "kpower", "kp%", "kp<", "kp>", "kp&", "kp&&", "kp|", "kp||", "kp:", "kp#", "kp[SPACE]", "kp@", "kp!",
		"kpmemstore", "kpmemrecall", "kpmemclear", "kpmem+", "kpmem-", "kpmem*", "kpmem/", "kp+-",
		"kpclear", "kpclearentry", "kpbinary", "kpoctal", "kpdecimal", "kphex",
		"lctrl", "lshift", "lalt", "lgui", "rctrl", "rshift", "ralt", "rgui",
		"mode",
		"audionext", "audioprev", "audiostop", "audioplay", "audiomute", "mediaselect",
		"www", "mail", "calculator", "computer",
		"acsearch", "achome", "acback", "acforward", "acstop", "acrefresh", "acbookmarks",
		"brightnessdown", "brightnessup", "displayswitch",
		"kbdillumtoggle", "kbdillumup",
		"eject", "sleep", "app1", "app2",
		"nonusbackslash", "application", "power",
		"execute", "help", "menu", "select",
		"stop", "again", "undo", "cut", "copy", "paste", "find", "mute", "volumeup", "volumedown", "kp", "kp=400",
		"international1", "international2", "international3", "international4", "international5",
		"international6", "international7", "international8", "international9",
		"lang1", "lang2", "lang3", "lang4", "lang5", "lang6", "lang7", "lang8", "lang9",
		"alterase", "cancel", "clear", "prior", "return2", "separator", "out", "oper", "clearagain", "crsel", "exsel",
		"thousandsseparator", "decimalseparator", "currencyunit", "currencysubunit",
	}

	local scancode_set = {}
	for key in ipairs(scancode_list) do
		scancode_set[key] = true
	end

	local gkfs = love.keyboard.getKeyFromScancode
	function love.keyboard.getKeyFromScancode(scancode)
		if (scancode_set[scancode]) then
			return gkfw(scancode)
		else
			return "unknown"
		end
	end
end