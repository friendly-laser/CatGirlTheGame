require 'tiled'

function load_level(filename)
	local level = {}

	level = {}
	level.tilesets = {}
	level.tileset_id = 1
	level.cols = 3
	level.rows = 3

    local tilesets,layers = TiledMap_Parse(filename)

	local tileset_id = 1
    for first_gid, path in pairs(tilesets.tiles) do
		local short_path = string.gsub(path, "^../", "")
		printf("Loading tileset %d `%s` (first_gid=%d)\n", tileset_id, path, first_gid);

		level.tilesets[tileset_id] = load_tileset(short_path, cTileW, cTileH)

		for id, tbl in pairs(tilesets.props) do
			printf("Have properties for tile %d:\n", id)
			for name, value in pairs(tbl) do
				printf("    %s = %s\n", name, value)
				if name == 'collide' then
					level.tilesets[tileset_id]['collide'][id+1] = value
				else
				printf("    --ignored\n");
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
		
		if gid == 385 then
			printf("QUAD for tile %d is %d,%d-- %d,%d\n", gid, x, y, x+tileW, y+tileH);
		end
		
		ts['quads'][gid] = love.graphics.newQuad(x, y, tileW, tileH, tilesetW, tilesetH)
		ts['collide'][gid] = 'none'
		x = x + tileW
		gid = gid + 1
	end

	--ts['quads'][1] = love.graphics.newQuad(0,  0, tileW, tileH, tilesetW, tilesetH)
	--ts['quads'][2] = love.graphics.newQuad(64, 0, tileW, tileH, tilesetW, tilesetH)
	--ts['quads'][3] = love.graphics.newQuad(0, 64, tileW, tileH, tilesetW, tilesetH)
	--ts['quads'][4] = love.graphics.newQuad(64, 64, tileW, tileH, tilesetW, tilesetH)

	--ts['collide'][385] = 'wall'
	--ts['collide'][449] = 'wall'
	--ts['collide'][2] = 'cloud'
	--ts['collide'][3] = 'none'
	--ts['collide'][4] = 'none'

	return ts
end
