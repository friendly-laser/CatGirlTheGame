
function draw_actor(actor)
	sprite = actor.sprite
	frame = sprite['frames'][actor.anim][actor.frame]

	love.graphics.draw(sprite.image, frame, actor.x, actor.y, 0, actor.flip, 1, sprite.origin_x)
end

function draw_actors()

	draw_actor(cDoll)

end

function draw_tiles(map)
	local level = cLevel
	local tilesets = cLevel.tilesets

	for j = 1, level.rows do
		for i = 1, level.cols do

			local tileid = map[j][i]
			local x = (i-1) * cTileW
			local y = (j-1) * cTileH

			if tileid > 0 then

				if tileid == 384 then
				--printf("Drawing tile %d at %d, %d\n", tileid, x, y)
				end

				love.graphics.draw(tilesets[level.tileset_id]['image'], tilesets[level.tileset_id]['quads'][tileid], x, y)

			end
		end
	end
end