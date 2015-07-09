require 'tiled'

function load_level(filename)
	local level = {}

	level = {}
	level.backgrounds = {}
	level.tilesets = {}
	level.layers = {}
	level.tileset_id = 1
	level.cols = 3
	level.rows = 3
	level.tileW = 8
	level.tileH = 8

	level.start_x = 0
	level.start_y = 0

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

    for tileset_id, ts in pairs(tilesets) do
    	local path = ts['file']
		local short_path = string.gsub(path, "^../", "")
		local first_gid = ts['first_gid'] 
		printf("Loading tileset %d `%s` (first_gid=%d)\n", tileset_id, path, first_gid);

		level.tilesets[tileset_id] = load_tileset(short_path, ts['tile_w'], ts['tile_h'])

		--level.tilesets[tileset_id]['first_gid'] = first_gid

		for id, tbl in pairs(ts.props) do
			--printf("Have properties for tile %d:\n", id)
			for name, value in pairs(tbl) do
				--printf("    %s = %s\n", name, value)
				--if name == 'collide' then
				level.tilesets[tileset_id][name][id+1] = value
				--else
				--printf("    --ignored\n");
				--end
			end
		end

		tileset_id = tileset_id + 1
    end

	level.rows = layers.height
	level.cols = layers.width
	level.colmap = make_matrix(layers.width, layers.height)

	local col = level.colmap

	--meh hack
	tileset_id = 1

	for layerid,layer in pairs(layers) do
		local map = nil

		if type(layerid) == "number" then
			level.layers[tonumber(layerid)] = make_matrix(layers.width, layers.height)
			map = level.layers[tonumber(layerid)]
		end

		if (type(layer) == "table") then for ty,row in pairs(layer) do
			if (type(row) == "table") then for tx,t in pairs(row) do 

				map[ty + 1][tx + 1] = t -- lua arrays are 1-based, so we add +1

				local test = level.tilesets[tileset_id]['collide'][t]

				if not(test == "none") or col[ty + 1][tx + 1] == "none" then
					col[ty + 1][tx + 1] = test
					--printf("Setting %d, %d to %s\n", tx, ty, test)
				end

			end end
		end end
	end

	local obj_id, object
	for obj_id,object in pairs(objects) do

		printf("Loading object %d `%s` (props:%p)\n", obj_id, object.name, object.props);

		if object.name == "Start" then

			level.start_x = object.x
			level.start_y = object.y

		end

		if object.props.collide then
		
			local i, j, x, y, w, h
			x = math.floor(object.x / level.tileW) + 1
			y = math.floor(object.y / level.tileH) + 1
			w = math.floor(object.w / level.tileW)
			h = math.floor(object.h / level.tileH)

			for j = 0, h-1 do
			for i = 0, w-1 do

				col[y + j][x + i] = object.props.collide

			end end
		end

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
	ts['anim_x'] = {}
	ts['anim_y'] = {}
	ts['anim_delay'] = {}

	ts['tile_w'] = tileW
	ts['tile_h'] = tileH

	local tilesetW, tilesetH = ts['image']:getWidth(), ts['image']:getHeight()

	ts['tile_pitch'] = math.floor(tilesetW / tileW)

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

	ts['collide'][0] = 'none' -- TODO: investigate this

	return ts
end

-- call this on window resize!
function update_BGQuads()
	for id, bg in pairs(cLevel.backgrounds) do

		local image = bg['image']

		bg['quad'] = love.graphics.newQuad(0, 0, cBaseW * cScaleW, cBaseH * cScaleH, image:getWidth(), image:getHeight())

	end
end

-- call sometimes
delays = {}
function anim_tiles(map, dt)
	local i, j

	--printf("Eat %f\n", dt);
	
	local tileset_id = 1

	local ts = cLevel.tilesets[tileset_id]

	for j = 1, 100 do
		for i = 1, 100 do

			local t = map[j][i]

			if ts['anim_delay'][t] then

				local tid = j * 100 + i
				
				if not(delays[tid]) then
					delays[tid] = ts['anim_delay'][t]
				end

				delays[tid] = delays[tid] - dt

				if delays[tid] <= 0 then
					delays[tid] = ts['anim_delay'][t]

				local mov_ind

				mov_ind = ts['tile_pitch'] * ts['anim_y'][t] + ts['anim_x'][t]			

				--printf("!!!!!! mov_ind = %d [%f]\n", mov_ind, ts['anim_delay'][t])

				map[j][i] = t + mov_ind
				
				end
			end

		end
	end
end
function anim_all_tiles(dt)
	for id = 1, table.getn(cLevel.layers) do
		anim_tiles(cLevel.layers[id], dt)
	end
end
