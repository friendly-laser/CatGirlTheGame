sprites = {}

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
