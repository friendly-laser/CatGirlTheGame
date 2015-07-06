sprites = {}

function load_sprite(id, filename, tileW, tileH)
	local spr = {}

	spr['image'] = love.graphics.newImage(filename)
	spr['frames'] = {}
	spr['max_frames'] = {}

	local W, H = spr['image']:getWidth(), spr['image']:getHeight()

	spr['origin_x'] = tileW / 2
	spr['bound_x'] = 20

	fill_anim_range(spr, 'idle', 0, 0, tileW, tileH, 10)
	fill_anim_range(spr, 'walk', 0, 64, tileW, tileH, 8)

	sprites[id] = spr

	return spr
end

function fill_anim_range(spr, name, base_x, base_y, tileW, tileH, maxf)
	local i, x

	local W, H = spr['image']:getWidth(), spr['image']:getHeight()

	spr['frames'][name] = {}
	
	x = base_x
	for i = 1, maxf do
		spr['frames'][name][i] = love.graphics.newQuad(x, base_y, tileW, tileH, W, H)
		x = x + tileW
	end

	spr['max_frames'][name] = maxf
end