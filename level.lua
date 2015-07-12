require 'tiled'

function load_level(filename)
	local level = {}

	level = {}
	level.backgrounds = {}
	level.tilesets = {}
	level.layers = {}
	level.layers_visible = {}
	level.npcs = {}
	level.objects = {}
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

	level.giant_ref_table = {}

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

		level.tilesets[tileset_id] = load_tileset(short_path, ts['tile_w'], ts['tile_h'], first_gid)

		local last_gid = first_gid + level.tilesets[tileset_id]['tiles_total']

		level.tilesets[tileset_id]['first_gid'] = first_gid
		level.tilesets[tileset_id]['last_gid'] = last_gid

		for id, tbl in pairs(ts.props) do
			--printf("Have properties for tile %d:\n", id)
			for name, value in pairs(tbl) do
				--printf("    %s = %s\n", name, value)
				level.tilesets[tileset_id][name][id+1] = value
			end
		end

		--stuff giant ref table
		local last_gid = level.tilesets[tileset_id]['last_gid']
		for gid = first_gid, last_gid do
			level.giant_ref_table[gid] = tileset_id
		end 

		tileset_id = tileset_id + 1
    end

	--hack "tile 0 (emptyness)" refs to tileset 1
	-- we will also have some hacks for "tile 0" in each tileset
	-- so it's all good
	level.giant_ref_table[0] = 1


	-- do something horrible....
	animation_hack(level, tilesets)


	level.colmap = make_matrix(level.cols, level.rows)
	level.hitmap = make_matrix(level.cols, level.rows)

	local col = level.colmap
	local hit = level.hitmap

	for layerid,layer in pairs(layers) do
		local map = nil

		if type(layerid) == "number" then
			level.layers_visible[tonumber(layerid)] = layer.visible or 1
			level.layers[tonumber(layerid)] = make_matrix(level.cols, level.rows)
			map = level.layers[tonumber(layerid)]
		end

		if (type(layer) == "table") then for ty,row in pairs(layer) do
			if (type(row) == "table") then for tx,t in pairs(row) do 

				map[ty + 1][tx + 1] = t -- lua arrays are 1-based, so we add +1

				-- empty tile
				if t == 0 then

				else

					local tileset_id = level.giant_ref_table[t]

					--printf("Got tile %d ==> tileset %d\n", t, tileset_id);

					local ctest = level.tilesets[tileset_id]['collide'][t]

					if not(ctest == "none") or col[ty + 1][tx + 1] == "none" then
						col[ty + 1][tx + 1] = ctest
						--printf("Setting %d, %d to %s\n", tx, ty, ctest)
					end

					local htest = level.tilesets[tileset_id]['hit'][t]

					if not(htest == "none") or hit[ty + 1][tx + 1] == "none" then
						hit[ty + 1][tx + 1] = htest
						--printf("Setting %d, %d to %s\n", tx, ty, htest)
					end

				end

			end end
		end end
	end

	-- hack: "remove" invisible layers from top of the layer stack
	level.num_layers = table.getn(level.layers)
	while level.layers_visible[level.num_layers] == 0 do
		level.num_layers = level.num_layers - 1
	end

	local obj_id, object
	for obj_id,object in pairs(objects) do

		printf("Loading object %d `%s` (props:%p)\n", obj_id, object.name, object.props);

		if object.gid then

			local tileset_id = level.giant_ref_table[object.gid]
			object.w = level.tilesets[tileset_id]['tile_w']
			object.h = level.tilesets[tileset_id]['tile_h']

			object.x = object.x
			object.y = object.y - object.h -- hack: check other tiled-draw-modes --

			object.props.collide = level.tilesets[tileset_id]['collide'][object.gid]
			object.props.hit = level.tilesets[tileset_id]['hit'][object.gid]
		end

		if object.name == "Start" then

			level.start_x = object.x
			level.start_y = object.y

		end

		if object.type == "Actor" then

			table.insert(level.npcs, make_actor(object.name, object.x, object.y))

			local id = table.getn(level.npcs)
			level.npcs[id].collide = object.props.collide
			level.npcs[id].hit = object.props.hit

		--elseif object.type == "" then

		elseif object.gid then

			table.insert(level.objects, object)

		end
--[[
		if object.props.collide then

			local i, j, x, y, w, h
			x = math.floor(object.x / level.tileW) + 1
			y = math.floor(object.y / level.tileH) + 1
			w = math.floor(object.w / level.tileW)
			h = math.floor(object.h / level.tileH)

			if x < 1 then x = 1 end
			if y < 1 then y = 1 end
			if x + w > level.cols then w = level.cols - x end
			if y + h > level.rows then h = level.rows - y end

			for j = 0, h-1 do
			for i = 0, w-1 do

				col[y + j][x + i] = object.props.collide

			end end

		end
--]]
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

function load_tileset(filename, tileW, tileH, first_gid)
	local ts = {}

	ts['image'] = love.graphics.newImage(filename)
	ts['quads'] = {}
	ts['collide'] = {}
	ts['hit'] = {}
	ts['anim_x'] = {}
	ts['anim_y'] = {}
	ts['anim_delay'] = {}

	ts['tile_w'] = tileW
	ts['tile_h'] = tileH

	local tilesetW, tilesetH = ts['image']:getWidth(), ts['image']:getHeight()

	ts['tile_pitch'] = math.floor(tilesetW / tileW)
	ts['tiles_total'] = ts['tile_pitch'] * math.floor(tilesetH / tileH)

	--printf("For tileset %s, chose pitch %d, total %d\n", filename, ts['tile_pitch'], ts['tiles_total'])

	local gid = first_gid or 1
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
		ts['hit'][gid] = 'none'
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

	for j = 1, 100 do
		for i = 1, 100 do

			local t = map[j][i]

			local tileset_id = cLevel.giant_ref_table[t]

			local ts = cLevel.tilesets[tileset_id]

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
	local num_layers = table.getn(cLevel.layers)

	for id = 1, num_layers do
		anim_tiles(cLevel.layers[id], dt)
	end
end

function anim_object(obj, dt)

	local t = obj.gid

	local tileset_id = cLevel.giant_ref_table[t]

	local ts = cLevel.tilesets[tileset_id]

	if ts['anim_delay'][t] then

		if not(obj.anim_delay) then
			obj.anim_delay = ts['anim_delay'][t]
		end

		obj.anim_delay = obj.anim_delay - dt

		if obj.anim_delay <= 0 then

			obj.anim_delay = ts['anim_delay'][t]

			local mov_ind

			mov_ind = ts['tile_pitch'] * ts['anim_y'][t] + ts['anim_x'][t]

			--printf("!!!!!! mov_ind = %d [%f]\n", mov_ind, ts['anim_delay'][t])

			obj.gid = t + mov_ind

		end
	end
end

function anim_objects(dt)
	local num_objects = table.getn(cLevel.objects)

	for id = 1, num_objects do
		anim_object(cLevel.objects[id], dt)
	end
end


function animation_hack(level, tilesets)

    for tileset_id, ts in pairs(tilesets) do
		local first_gid = ts['first_gid']

		printf("Animating tileset %d (first_gid=%d)\n", tileset_id, first_gid);

		for id, tbl in pairs(ts.anim) do
			--printf("Have anim for tile %d:\n", id)
			local max_frames = table.getn(tbl)
			for ind, frame in pairs(tbl) do
				local next, next_ind
				if (ind < max_frames) then
					next_ind = ind + 1
					next = tbl[ind + 1]
				else
					next_ind = 1
					next = tbl[1]
				end
				local gid = frame["gid"] + ts.first_gid

				--printf("   frame %d = , next = %d, gid=%d ", ind, next_ind, gid)
				--dumps(frame)

				local src_id = frame["gid"] + 1
				local src_y = math.floor(src_id / ts['tile_h'])
				local src_x = src_id - src_y * ts['tile_h']
				local dest_id = next["gid"] + 1
				local dest_y = math.floor(dest_id / ts['tile_h'])
				local dest_x = dest_id - dest_y * ts['tile_h']

				local anim_to, anim_x, anim_y

				anim_to = next["gid"] + ts.first_gid

				anim_x = dest_x - src_x
				anim_y = dest_y - src_y

				--printf("   anim_to = %d, anim_x = %d, anim_y = %d\n", anim_to, anim_x, anim_y);

				level.tilesets[tileset_id]['anim_delay'][gid] = frame['delay']
				level.tilesets[tileset_id]['anim_x'][gid] = anim_x
				level.tilesets[tileset_id]['anim_y'][gid] = anim_y

			end
		end

    end

end