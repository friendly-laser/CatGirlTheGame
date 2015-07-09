require 'util'
require 'sprite'
require 'level'
require 'paint'
require 'phys'
require 'control'
require 'camera'
require 'actor'

canvas = nil
cLevel = nil
cDoll = nil

cBaseW = 320
cBaseH = 270
cScaleW = 2
cScaleH = 2

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

function love.load()

	canvas = love.graphics.newCanvas(cBaseW, cBaseH)
	canvas:setFilter("nearest", "nearest")

	love.window.setMode(cBaseW * cScaleW, cBaseH * cScaleH, {} )
	love.window.setTitle("Catgirl!")
	love.window.setIcon( love.image.newImageData( "icon.png" ) )

	cLevel = load_level("Levels/level1.tmx")

	update_BGQuads(cLevel)

	load_sprite(1, "Sprites/Characters/Catgirl/catgirl_both_anim_64x64_sheet.png", 64, 64)

	cDoll = make_actor(1, 30, -30)

	sound = love.audio.newSource("Music/level1.ogg")
	sound:setLooping(true)
	love.audio.play(sound)

	love.graphics.setBackgroundColor(0,0,0)
end

function love.draw()

	-- Draw to framebuffer
	love.graphics.setCanvas(canvas) --This sets the draw target to the canvas
	canvas:clear(0,0,0)

	-- Push camera tranform
	camera:set()

	-- DRAW
	draw_frame()

	-- Pop camera transform
	camera:unset()

	love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 0, 0)

	-- Blit framebuffer to screen
	love.graphics.setCanvas() --This sets the target back to the screen
	love.graphics.draw(canvas, 0, 0, 0, cScaleW, cScaleH)

	love.graphics.print(doll.spring, 500, 10)
	love.graphics.print(doll.spring_release, 500, 20)
	love.graphics.print(cDoll.force_y, 500, 30)
--	love.graphics.print(trif(love.keyboard.isDown(" "),"HOLD","REL"), 10, 30)

end

function love.update(dt)

	doll:control()
	doll:update(dt)
	doll:apply(cDoll)

	phys_loop(dt)

	actor_apply_anim(cDoll, dt)

	camera:follow(cDoll)

end
