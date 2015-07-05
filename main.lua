require 'util'

function load_tileset(id, filename, tileW, tileH)
	local ts = {}

	ts['image'] = love.graphics.newImage(filename)
	ts['quads'] = {}
	ts['collide'] = {}

	local tilesetW, tilesetH = ts['image']:getWidth(), ts['image']:getHeight()

	ts['quads'][1] = love.graphics.newQuad(0,  0, tileW, tileH, tilesetW, tilesetH)
	ts['quads'][2] = love.graphics.newQuad(64, 0, tileW, tileH, tilesetW, tilesetH)
	ts['quads'][3] = love.graphics.newQuad(0, 64, tileW, tileH, tilesetW, tilesetH)
	ts['quads'][4] = love.graphics.newQuad(64, 64, tileW, tileH, tilesetW, tilesetH)

	ts['collide'][1] = 'wall'
	ts['collide'][2] = 'cloud'
	ts['collide'][3] = 'none'
	ts['collide'][4] = 'none'

	tilesets[id] = ts
end

function load_sprite(id, filename, tileW, tileH)
	local spr = {}

	spr['image'] = love.graphics.newImage(filename)
	spr['frames'] = {}
	spr['max_frames'] = {}

	local W, H = spr['image']:getWidth(), spr['image']:getHeight()

	spr['origin_x'] = tileW / 2

	spr['max_frames']['idle'] = 1;
	spr['max_frames']['walk'] = 4;
	spr['frames']['idle'] = {}
	spr['frames']['walk'] = {}

	spr['frames']['idle'][1] = love.graphics.newQuad(0,  0, tileW, tileH, W, H)

	spr['frames']['walk'][1] = love.graphics.newQuad(0,  0, tileW, tileH, W, H)
	spr['frames']['walk'][2] = love.graphics.newQuad(32,  0, tileW, tileH, W, H)
	spr['frames']['walk'][3] = love.graphics.newQuad(64,  0, tileW, tileH, W, H)
	spr['frames']['walk'][4] = love.graphics.newQuad(32+64,  0, tileW, tileH, W, H)

	sprites[id] = spr
end

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

tilesets = {}
sprites = {}

level = {}
level.tilemap = make_matrix(16, 16)
level.cols = 3
level.rows = 3
level.tileset_id = 1
level.tilemap = {
	{ 3, 3, 3 },
	{ 2, 3, 3 },
	{ 1, 1, 1 },
}

love.window.setMode( 320, 270, {} )
love.window.setTitle("Catgirl!")

function draw_actor(actor)
	sprite = actor.sprite
	frame = sprite['frames'][actor.anim][actor.frame]

	love.graphics.draw(sprite.image, frame, actor.x, actor.y, 0, actor.flip, 1, sprite.origin_x)
end

function draw_actors()

	draw_actor(elvis)

end

function draw_tiles()
	for j = 1, level.rows do
		for i = 1, level.cols do

			local tileid = level.tilemap[j][i]
			local x = (i-1) * 64
			local y = (j-1) * 64

			love.graphics.draw(tilesets[level.tileset_id]['image'], tilesets[level.tileset_id]['quads'][tileid], x, y)

		end
	end
end

function love.load()
	load_tileset(1, "tileset1.png", 64, 64)
	load_sprite(1, "elvissheet.png", 32, 64)
	
	elvis = make_actor(1, 30, -30)

	raw_icon = love.image.newImageData( "icon.png" )

	love.window.setIcon( raw_icon )
	
	sound = love.audio.newSource("music.ogg")
	love.audio.play(sound)
end

function love.draw()
	draw_tiles()
	draw_actors()
	
	love.graphics.print(elvis.spring, 10, 10)
	love.graphics.print(elvis.spring_force, 10, 20)
	love.graphics.print(trif(love.keyboard.isDown(" "),"HOLD","REL"), 10, 30)
end

function doll_control(actor, dt)

	actor.anim_delay = actor.anim_delay - dt
	actor.anim = 'idle'
	actor.force_x = 0

	if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
		actor.force_x = 1
		actor.flip = 1
		actor.anim = 'walk'
	elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
		actor.force_x = -1
		actor.flip = -1
		actor.anim = 'walk'
	end

	if love.keyboard.isDown(" ") then
		if actor.standing == 1 then
			actor.spring = actor.spring + 1
		end
	end

	if not(love.keyboard.isDown(" ")) or actor.spring > 8 then
		if actor.spring > 0 then
			actor.spring_force = actor.spring
			actor.spring = 0
		end
	end

	if actor.anim_delay <= 0 then
		actor.anim_delay = 0.1000
		actor.frame = actor.frame + 1
	end

	if actor.frame > actor.sprite['max_frames'][actor.anim] then
		actor.frame = 1
	end

end

function love.update(dt)

	doll_control(elvis, dt)

	actor_phys(elvis, dt)

end

function rect_vs_rect(x1,y1,w1,h1, x2,y2,w2,h2)
	return x1 < x2+w2 and
		x2 < x1+w1 and
		y1 < y2+h2 and
		y2 < y1+h1
end
function box_vs_box(box1, box2)
	return box1.x < box2.x + box2.w and
		box2.x < box1.x + box1.w and
		box1.y < box2.y + box2.h and
		box2.y < box1.y + box1.h
end
function box_above_box(box1, box2)
	return box1.y + box1.h <= box2.y + 1
end
function box_leftof_box(box1, box2)

end
function box_rightof_box(box1, box2)

end

function tile_collide(actor, dx, dy)
-- Try moving
	local new_x, new_y

	new_x = actor.x + dx
	new_y = actor.y + dy

-- Collide with tiles
	for j = 1, level.rows do
		for i = 1, level.cols do

			local tileid = level.tilemap[j][i]
			local x = (i-1) * 64
			local y = (j-1) * 64

			local mode = tilesets[level.tileset_id]['collide'][tileid]

			local actor_box = {}
			actor_box.x = new_x - actor.sprite.origin_x
			actor_box.y = new_y
			actor_box.w = 64
			actor_box.h = 64

			local tile_box = {}
			tile_box.x = x
			tile_box.y = y
			tile_box.w = 64
			tile_box.h = 64
			
			local collided = false

			if mode == 'wall' then
				if box_vs_box(actor_box, tile_box) then
					collided = true
				end
			end
			if mode == 'cloud' then
				if actor.force_y > 0 and box_above_box(actor_box, tile_box) and box_vs_box(actor_box, tile_box) then
					collided = true
				end
			end
			
			if collided == true then
				new_x = actor.x
				new_y = actor.y
				if (dy > 0) then
					actor.standing = 1
				end
			end
		end
	end

	actor.x = new_x
	actor.y = new_y
end

function actor_phys(actor, dt)

	-- jump
	if actor.spring_force > 0 then
		actor.force_y = -actor.spring_force * 3
		actor.spring_force = 0
	end

	-- gravity
	if actor.force_y < 8 then
		actor.force_y = actor.force_y + 1
	end

	-- reset "standing" flag (will be set during collision)
	actor.standing = 0

-- 2D Game magic:
-- collide X and Y movements separately!
-- this allows "classic" 2D effects like bumping head into ceilings
-- and jumping along walls without having a vector-based collision system
	long_collide(actor, 'x', actor.force_x)
	long_collide(actor, 'y', actor.force_y)
end

function long_collide(actor, mode, dm)
	local dir = 1
	local amnt = 1

	if dm == 0 then return end

	amnt = math.abs(dm)
	if dm < 0 then dir = -1 else dir = 1 end

	if amnt > 4 then amnt = 4 end
	
	if mode == 'x' then
		for i = 1, amnt do
			tile_collide(actor, dir, 0)
		end
	end
	if mode == 'y' then
		for i = 1, amnt do
			tile_collide(actor, 0, dir)
		end
	end	
end
