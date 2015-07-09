require 'tiled'

function load_level(filename)
	local level = {}

	level = {}
	level.backgrounds = {}
	level.tilesets = {}
	level.tileset_id = 1
	level.cols = 3
	level.rows = 3
	level.tileW = 8
	level.tileH = 8

    local info,tilesets,layers,backgrounds,objects = TiledMap_Parse(filename)

	level.tileW = info.tileW
	level.tileH = info.tileH
	level.cols = info.cols
	level.rows = info.rows

	local bg_id, background
	for bg_id,background in pairs(backgrounds) do
		local path = background['file']
		local short_path = string.gsub(path, "^../", "")
		local scaleX = background['props']['scaleX'] or 1
		printf("Loading background %d `%s`\n", bg_id, path);

		level.backgrounds[bg_id] = load_background(short_path, scaleX)
	end
	
	local tileset_id = 1
    for first_gid, path in pairs(tilesets.tiles) do
		local short_path = string.gsub(path, "^../", "")
		printf("Loading tileset %d `%s` (first_gid=%d)\n", tileset_id, path, first_gid);

		level.tilesets[tileset_id] = load_tileset(short_path, level.tileW, level.tileH)

		for id, tbl in pairs(tilesets.props) do
			--printf("Have properties for tile %d:\n", id)
			for name, value in pairs(tbl) do
				--printf("    %s = %s\n", name, value)
				if name == 'collide' then
					level.tilesets[tileset_id]['collide'][id+1] = value
				else
				--printf("    --ignored\n");
				end
			end
		end
		
		tileset_id = tileset_id + 1
    end

	level.rows = layers.height
	level.cols = layers.width
	level.bgmap = make_matrix(layers.width, layers.height)
	level.tilemap = make_matrix(layers.width, layers.height)

	for layerid,layer in pairs(layers) do
		local map = nil

		if type(layerid) == "number" and tonumber(layerid) == 1 then
			map = level.bgmap
		end
		if type(layerid) == "number" and tonumber(layerid) == 2 then
			map = level.tilemap
		end

		if (type(layer) == "table") then for ty,row in pairs(layer) do
			if (type(row) == "table") then for tx,t in pairs(row) do 
	
				map[ty + 1][tx + 1] = t -- lua arrays are 1-based, so we add +1

			end end
		end end
	end

	return level
end

function load_background(filename, scaleX)
	local bg = {}

	bg['image'] = love.graphics.newImage(filename)
	bg['scaleX'] = scaleX

	bg['image']:setWrap("repeat", "clamp")

	return bg
end

function load_tileset(filename, tileW, tileH)
	local ts = {}

	ts['image'] = love.graphics.newImage(filename)
	ts['quads'] = {}
	ts['collide'] = {}

	local tilesetW, tilesetH = ts['image']:getWidth(), ts['image']:getHeight()

	local gid = 1
	local x = 0
	local y = 0
	while true do
		--printf("Gid=%d, X=%d, Y=%d | W=%d, H=%d\n", gid, x, y, tilesetW, tilesetH)
		if x + tileW > tilesetW then
			y = y + tileH
			x = 0
		end
		if (y + tileH > tilesetH) then
			break
		end

		ts['quads'][gid] = love.graphics.newQuad(x, y, tileW, tileH, tilesetW, tilesetH)
		ts['collide'][gid] = 'none'
		x = x + tileW
		gid = gid + 1
	end

	return ts
end

-- call this on window resize!
function update_BGQuads()
	for id, bg in pairs(cLevel.backgrounds) do

		local image = bg['image']

		bg['quad'] = love.graphics.newQuad(0, 0, cBaseW * cScaleW, cBaseH * cScaleH, image:getWidth(), image:getHeight())

	end
end