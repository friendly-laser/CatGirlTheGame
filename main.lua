require 'util'
require 'sprite'
require 'level'
require 'paint'
require 'phys'
require 'control'

canvas = nil
cLevel = nil
cDoll = nil
cTileW = 8
cTileH = 8
cBaseW = 320
cBaseH = 270

cScaleW = 2
cScaleH = 2

function make_actor(sprite_id, x, y)
	local actor = {}

	actor.sprite_id = sprite_id
	actor.sprite = sprites[sprite_id]
	actor.x = x
	actor.y = y
	
	actor.anim = 'idle'
	actor.frame = 1
	actor.flip = 1
	actor.anim_delay = 0

	actor.force_x = 0
	actor.force_y = 0
	actor.spring = 0
	actor.spring_force = 0
	actor.standing = 0

	return actor
end


function love.load()

	canvas = love.graphics.newCanvas(cBaseW, cBaseH)
	canvas:setFilter("nearest", "nearest")

	love.window.setMode(cBaseW * cScaleW, cBaseH * cScaleH, {} )
	love.window.setTitle("Catgirl!")
	love.window.setIcon( love.image.newImageData( "icon.png" ) )

	cLevel = load_level("Levels/level1.tmx")

	load_sprite(1, "elvissheet.png", 32, 64)

	cDoll = make_actor(1, 30, -30)

	sound = love.audio.newSource("music.ogg")
	love.audio.play(sound)

end

function love.draw()

	-- Draw to framebuffer
	love.graphics.setCanvas(canvas) --This sets the draw target to the canvas

	draw_tiles(cLevel.bgmap)
	draw_tiles(cLevel.tilemap)
	draw_actors()

	-- Blit framebuffer to screen
	love.graphics.setCanvas() --This sets the target back to the screen
	love.graphics.draw(canvas, 0, 0, 0, cScaleW, cScaleH)

--	love.graphics.print(elvis.spring, 10, 10)
--	love.graphics.print(elvis.spring_force, 10, 20)
--	love.graphics.print(trif(love.keyboard.isDown(" "),"HOLD","REL"), 10, 30)
end

function love.update(dt)

	doll_control(cDoll, dt)
	actor_phys(cDoll, dt)

end