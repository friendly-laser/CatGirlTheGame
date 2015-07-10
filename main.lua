require 'util'
require 'sprite'
require 'level'
require 'paint'
require 'phys'
require 'control'
require 'camera'
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

cBaseW = 480
cBaseH = 270
cScaleW = 2
cScaleH = 2
cPanX = 0
cPanY = 0

capPhysFPS = 30
cPhysDelay = 0

cGamepad = nil

function love.joystickadded(joy)
	if cGamepad == nil then
		printf("Got gamepad!!!\n")
		cGamepad = joy
	end
end
function love.joystickremoved(joy)
	if cGamepad == joy then
		cGamepad = nil
	end
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

	love.window.setMode(cBaseW * cScaleW, cBaseH * cScaleH, {fullscreen=not(cRes.win), display=cRes.display} )
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

	sound = love.audio.newSource("Music/level1.ogg")
	sound:setLooping(true)
	love.audio.play(sound)

	love.graphics.setBackgroundColor(0,0,0)
end

function love.draw()

	-- Draw to framebuffer
	love.graphics.setCanvas(canvas)
	canvas:clear(0,0,0)

	loveHandler:draw()

	-- Blit framebuffer to screen
	love.graphics.setCanvas()
	love.graphics.draw(canvas, 0, 0, 0, cScaleW, cScaleH)

--[[
	love.graphics.print(doll.spring, 500, 10)
	love.graphics.print(doll.spring_release, 500, 20)
	love.graphics.print(cDoll.force_y, 500, 30)
--	love.graphics.print(trif(love.keyboard.isDown(" "),"HOLD","REL"), 10, 30)
--]]
end

function love.update(dt)

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