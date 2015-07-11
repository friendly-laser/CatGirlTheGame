function draw_backgrounds()

	for id, bg in pairs(cLevel.backgrounds) do

		local x = camera.x * bg.scaleX

		x = math.floor(x)

		love.graphics.draw(bg.image, bg.quad, x, 0)

	end

end

function draw_actor(actor)
	sprite = actor.sprite
	frame = sprite['frames'][actor.anim][actor.frame]

	if actor.effect == "flicker" then

		if (math.floor(math.sin(actor.effect_delay*25)) % 2 == 0) then
			return
		end

	end

	love.graphics.draw(sprite.image, frame, actor.x + sprite.origin_x, actor.y, 0, actor.flip, 1, sprite.origin_x)
end

function draw_actors()

	local i, doll
	for i, doll in pairs(cLevel.npcs) do

		draw_actor(doll)

	end

	draw_actor(cDoll)

end

function draw_tiles(map)
	local level = cLevel
	local tilesets = cLevel.tilesets

	local tx,ty,tw,th = camera:getTileBounds()

	local func_draw = love.graphics.draw

	for j = ty, th do
		for i = tx, tw do

			local tileid = map[j][i]
			local x = (i-1) * level.tileW
			local y = (j-1) * level.tileH

			if tileid > 0 then

				local tileset_id = level.giant_ref_table[tileid]

				--tileid = tileid - tilesets[tileset_id].first_gid + 1

				y = y - tilesets[tileset_id]['tile_h'] + level.tileH

				func_draw(tilesets[tileset_id]['image'], tilesets[tileset_id]['quads'][tileid], x, y)

			end
		end
	end
end

function draw_frame()

	draw_backgrounds()

	local last_layer = cLevel.num_layers

	for id = 1, last_layer - 1 do
		if cLevel.layers_visible[id] == 1 then
			draw_tiles(cLevel.layers[id])
		end
	end

	draw_actors()

	if cLevel.layers_visible[last_layer] == 1 then
		draw_tiles(cLevel.layers[last_layer])
	end

end