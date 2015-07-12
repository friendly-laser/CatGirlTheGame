require 'util'
require 'sprite'
require 'level'
require 'paint'
require 'phys'
require 'control'
require 'camera'
require 'role'
require 'actor'
require 'game'
require 'mainmenu'

loveHandler = mainmenu

canvas = nil
cLevel = nil
cDoll = nil

cConfig = nil
cRes = nil -- current resolution
cResolutions = nil -- list of resolutions

cVsync = false

cBaseW = 480
cBaseH = 270
cScaleW = 2
cScaleH = 2
cPanX = 0
cPanY = 0

capPhysFPS = 30
cPhysDelay = 0



function love.joystickadded(joy)
	vpad:setJoystick(joy)
end
function love.joystickremoved(joy)
	vpad:setJoystick()
end


sounds = {}
music = nil
function load_sounds()
	local dir = "Sounds"
	local files = love.filesystem.getDirectoryItems(dir)
	local k, file
	for k, file in ipairs(files) do
		if string.ends(file, ".wav") then
			local short = string.sub(file,1,string.len(file)-4) -- remove extension
			local fullname = dir .. '/' .. file
			sounds[short] = love.sound.newSoundData(fullname)
		end
	end
end
function play_sound(name)
	local source = love.audio.newSource(sounds[name])
	source:setVolume(cConfig.sounds / 100)
	love.audio.play(source)
end


function pick_volume(config)
	config_apply_master(config, config.master)
	config_apply_sounds(config, config.sounds)
	config_apply_music(config, config.music)
end

function config_apply_master(config, vol)
	config.master = math.max(0, math.min(tonumber(vol or 100), 100))
	love.audio.setVolume(config.master / 100)
end
function config_apply_sounds(config, vol)
	config.sounds = math.max(0, math.min(tonumber(vol or 100), 100))
	local n, sound
	local sound_factor = config.sounds / 100
	for n, sound in pairs(sounds) do
		--sound:setVolume(sound_factor)
	end
end
function config_apply_music(config, vol)
	config.music = math.max(0, math.min(tonumber(vol or 100), 100))
	music:setVolume(config.music / 100)
end

function config_apply_res(config, res)
	config.fullscreen = trif(res.win, "false", "true")
	config.width = res.w
	config.height = res.h
	config.display = res.display
end

function write_config(config)
	local data = ini1dump(config)
	love.filesystem.write("config.ini", data)
end

function read_config()
	local config = {}

	filename = "config.ini"

	if not(love.filesystem.exists(filename)) then
		printf("File '%s' does not exist!\n", filename)
		return config
	end

	for line in love.filesystem.lines(filename) do
		k,v = line:match("^([%w%p]-)%s*=%s*(.*)$")
		if k and v then
			config[k] = v
		end
	end

	return config
end

function configured_resolution()
	local config = cConfig

	local res = make_resolution(
		tonumber(config.display or 1),
		"default",
		trif(config.fullscreen == "true", false, true),
		tonumber(config.width or 480),
		tonumber(config.height or 270)
	)

	return res
end

function pick_resolution()
	cConfig = read_config()
	cResolutions = find_resolutions()

	local res = configured_resolution()

	-- see if it's valid
	local valid, _ = match_res(res)

	-- if invalid, pick new one (top)
	if (valid == 0) then
		res = cResolutions[1]
	end

	cRes = res

	cBaseW = res.base_w
	cBaseH = res.base_h
	cScaleW = res.scale_x
	cScaleH = res.scale_y
	cPanX = res.pan_x
	cPanX = res.pan_x
end

function setWindowMode()

	love.window.setMode(cBaseW * cScaleW, cBaseH * cScaleH, {fullscreen=not(cRes.win), display=cRes.display, vsync=cVsync} )
	love.window.setTitle("Catgirl!")
	love.window.setIcon( wIcon )

	canvas = love.graphics.newCanvas(cBaseW, cBaseH)
	canvas:setFilter("nearest", "nearest")

	camera:setSize(cBaseW, cBaseH)

end

function love.load()

	wIcon = love.image.newImageData( "icon.png" )

	pick_resolution()

	setWindowMode()

	menu_res_init(cRes)

	load_levels()

	sprites_parse_xml("sprites.xml")
	roles_parse_xml("roles.xml")

	load_sounds()

	music = love.audio.newSource("Music/level1.ogg")
	music:setLooping(true)

	pick_volume(cConfig)

	love.audio.play(music)

	love.graphics.setBackgroundColor(0,0,0)

	vpad:init_generic()

end

function love.draw()

	-- Draw to framebuffer
	love.graphics.setCanvas(canvas)
	canvas:clear(0,0,0)

	loveHandler:draw()

	-- Blit framebuffer to screen
	love.graphics.setCanvas()
	love.graphics.draw(canvas, 0, 0, 0, cScaleW, cScaleH)

	--vpad:draw()

--[[
	love.graphics.print(doll.spring, 500, 10)
	love.graphics.print(doll.spring_release, 500, 20)
	love.graphics.print(cDoll.force_y, 500, 30)
--	love.graphics.print(trif(love.keyboard.isDown(" "),"HOLD","REL"), 10, 30)
--]]
end

function love.update(dt)

	vpad:control()
	vpad:update(dt)

	loveHandler:update(dt)

end

function restart_level(filename)

	cLevel = load_level("Levels/" .. filename)

	update_BGQuads(cLevel)

	cDoll = make_actor("catgirl", cLevel.start_x, cLevel.start_y)

	camera:follow(cDoll)

end

function abort_game()

	cLevel = nil
	cDoll = nil

	loveHandler = mainmenu

end