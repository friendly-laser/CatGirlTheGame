sprites = {}

function sprite_load_xml(node)
	local spr = {}

	local id, imagefilename, frameW, frameH = node.xarg.name, node.xarg.image, node.xarg.framewidth, node.xarg.frameheight

	spr['image'] = love.graphics.newImage(imagefilename)
	spr['frames'] = {}
	spr['delays'] = {}
	spr['max_frames'] = {}

	local tileW = frameW
	local tileH = frameH

	local W, H = spr['image']:getWidth(), spr['image']:getHeight()

	spr['frame_w'] = tileW
	spr['frame_h'] = tileH

	spr['origin_x'] = tileW / 2

	for a, sub in ipairs(node) do
		if (sub.label == "box") then
			spr['bound_x'] = tonumber(sub.xarg.x)
			spr['bound_y'] = tonumber(sub.xarg.y)
			spr['bound_w'] = tonumber(sub.xarg.w)
			spr['bound_h'] = tonumber(sub.xarg.h)
		end
		if (sub.label == "animation") then
			local anim, row, col, maxf, delay =
				sub.xarg.name, tonumber(sub.xarg.row), tonumber(sub.xarg.col),
				tonumber(sub.xarg.frames), tonumber(sub.xarg.delay)
			fill_anim_range(spr, anim, (col-1)* tileW, (row-1) * tileH, tileW, tileH, maxf, delay)
		end
	end

	sprites[id] = spr

	return spr
end

function sprites_parse_xml(filename)
    local xml = LoadXML(love.filesystem.read(filename))
	local root = xml[2]
	if root.label == "sprite" then
		sprite_load_xml(root)
	end
	if root.label == "sprites" then
		for a, node in ipairs(root) do
			sprite_load_xml(node)
		end
	end
end

function load_sprite(id, filename, tileW, tileH)
	local spr = {}

	spr['image'] = love.graphics.newImage(filename)
	spr['frames'] = {}
	spr['delays'] = {}
	spr['max_frames'] = {}

	local W, H = spr['image']:getWidth(), spr['image']:getHeight()

	spr['origin_x'] = tileW / 2
	spr['bound_x'] = 20
	spr['bound_y'] = 24
	spr['bound_w'] = tileW - spr['bound_x'] * 2
	spr['bound_h'] = tileH - spr['bound_y']

	fill_anim_range(spr, 'idle', 0, 0, tileW, tileH, 10, 0.2000)
	fill_anim_range(spr, 'walk', 0, 64, tileW, tileH, 8, 0.1000)

	fill_anim_range(spr, 'rise', 64, 64, tileW, tileH, 1, 0.1000)
	fill_anim_range(spr, 'vrise', 64, 64, tileW, tileH, 1, 0.1000)
	fill_anim_range(spr, 'fall', 64, 64, tileW, tileH, 1, 0.1000)

	spr['frame_w'] = tileW
	spr['frame_h'] = tileH

	sprites[id] = spr

	return spr
end

function fill_anim_range(spr, name, base_x, base_y, tileW, tileH, maxf, tDelay)
	local i, x

	local W, H = spr['image']:getWidth(), spr['image']:getHeight()

	spr['frames'][name] = {}
	spr['delays'][name] = {}

	x = base_x
	for i = 1, maxf do
		spr['frames'][name][i] = love.graphics.newQuad(x, base_y, tileW, tileH, W, H)
		spr['delays'][name][i] = tDelay
		x = x + tileW
	end

	spr['max_frames'][name] = maxf
end