COLLISION_NONE = 0
COLLISION_WALL = 0xFF
COLLISION_CLOUD = 0x01

function tiles_around_actor(level, actor)
	local atx = math.floor(actor.x / level.tileW)
	local aty = math.floor(actor.y / level.tileH)

	local atw = math.floor((actor.x+actor.w) / level.tileW)
	local ath = math.floor((actor.y+actor.h) / level.tileH)

	atx = atx - 1
	aty = aty - 1
	atw = atw + 2
	ath = ath + 2

	if (atx < 1) then atx = 1 end
	if (aty < 1) then aty = 1 end
	if (atw > level.cols) then atw = level.cols end
	if (ath > level.rows) then ath = level.rows end

	return atx,aty,atw,ath
end


function rect_vs_rect(x1,y1,w1,h1, x2,y2,w2,h2)
	return x1 < x2+w2 and
		x2 < x1+w1 and
		y1 < y2+h2 and
		y2 < y1+h1
end
function box_vs_box(box1, box2)
	return
		box1.x < box2.x + box2.w and
		box2.x < box1.x + box1.w and
		box1.y < box2.y + box2.h and
		box2.y < box1.y + box1.h
end
function box_above_box(box1, box2)
	return box1.y + box1.h <= box2.y + 1
end
function box_leftof_box(box1, box2)
	return box1.x + box1.w <= box2.x + 1
end
function box_rightof_box(box1, box2)
	return box2.x + box2.w <= box1.x + 1
end

function actor_onCollision(actor, dx, dy, type, arg1, arg2)
	if (dy < 0) then
		actor.force_y = 0
	end
	if (dy > 0) then
		actor.standing = 1
	end
	if (dx > 0) then
		actor.bumping_right = 1
	end
	if (dx < 0) then
		actor.bumping_left = 1
	end
end

function actor_onHit(actor, hit, dx,  dy, type, arg1, arg2)
	if (hit == "bounce") then
		actor.force_y = -20
	end
	if (hit == "damage" and actor.effect == "") then
		actor.force_y = -15
		actor.force_x = -15 * actor.flip
		actor_damage(actor, 1);
	end
end

function npc_collide(actor, dx, dy)
	local level = cLevel

-- Try moving
	local new_x, new_y

	new_x = actor.x + dx
	new_y = actor.y + dy

	local actor_box = {}
	actor_box.x = new_x + actor.sprite.bound_x
	actor_box.y = new_y + actor.sprite.bound_y
	actor_box.w = actor.sprite.bound_w
	actor_box.h = actor.sprite.bound_h

-- Collide with actors
	local i, npc
	for i, npc in pairs(level.npcs) do
	if npc ~= actor then

		local mode = npc.collide or "none"
		local hit = npc.hit or "none"

		if mode ~= "none" or hit ~= "none" then

			local actor2_box = {}
			actor2_box.x = npc.x + npc.sprite.bound_x
			actor2_box.y = npc.y + npc.sprite.bound_y
			actor2_box.w = npc.sprite.bound_w
			actor2_box.h = npc.sprite.bound_h

			local collided = false
			local above = false

			collided = box_vs_box(actor_box, actor2_box)
			above = box_above_box(actor_box, actor2_box)

			if mode == 'cloud' then
				if actor.force_y > 0 and above and collided then
					collided = true
				else
					collided = false
				end
			end

			if collided == true then

				if above == true then
					actor.standing_on = npc
				end

				if mode ~= 'none' then
					actor.collided = true
					npc.force_x = dx

					actor_onCollision(actor, dx, dy, "npc", npc)
				end

				actor_onHit(actor, hit, dx, dy, "npc", npc)

			end

		end

	end end

end

function tile_collide(actor, dx, dy)
	local level = cLevel
	local tilesets = cLevel.tilesets

-- Try moving
	local new_x, new_y

	new_x = actor.x + dx
	new_y = actor.y + dy

	local actor_box = {}
	actor_box.x = new_x + actor.sprite.bound_x
	actor_box.y = new_y + actor.sprite.bound_y
	actor_box.w = actor.sprite.bound_w
	actor_box.h = actor.sprite.bound_h

-- Collide with tiles
	local tx,ty,tw,th = tiles_around_actor(level, actor_box);

	for j = ty, th do
	for i = tx, tw do

		--local tileid = level.tilemap[j][i]
		--local mode = tilesets[level.tileset_id]['collide'][tileid]
		local mode = level.colmap[j][i]
		local hit = level.hitmap[j][i]

		if mode ~= "none" or hit ~= "none" then

			local x = (i-1) * level.tileW
			local y = (j-1) * level.tileH

			local tile_box = {}
			tile_box.x = x
			tile_box.y = y
			tile_box.w = level.tileW
			tile_box.h = level.tileH

			local collided = false

			if mode == 0 or mode == "none" then
				if j == th - 1 then
					if i == tx + 1 then
						actor.ledge_left = 1
					end
					if i == tw - 1 then
						actor.ledge_right = 1
					end
				end
			end

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
			if mode == 'lfield' then
				if actor.force_x > 0 and box_leftof_box(actor_box, tile_box) and box_vs_box(actor_box, tile_box) then
					collided = true
				end
			end
			if mode == 'rfield' then
				if actor.force_x < 0 and box_rightof_box(actor_box, tile_box) and box_vs_box(actor_box, tile_box) then
					collided = true
				end
			end

			if collided == true then
				actor.collided = true
				actor_onHit(actor, hit, dx, dy, "tile", i, j)
				actor_onCollision(actor, dx, dy, "tile", i, j)
			end

		end
	end end

end

function long_collide(actor, mode, dm)
	local dir = 1
	local amnt = 1

	if dm == 0 then return end

	amnt = math.abs(dm)
	if dm < 0 then dir = -1 else dir = 1 end

	--if amnt > 8 then amnt = 8 end

	if mode == 'x' then
		for i = 1, amnt do
			actor.collided = false
			tile_collide(actor, dir, 0)
			npc_collide(actor, dir, 0)
			if (actor.collided == false) then
				actor.x = actor.x + dir
				actor_post_move(actor, dir, 0)
			end
		end
	end
	if mode == 'y' then
		for i = 1, amnt do
			actor.collided = false
			tile_collide(actor, 0, dir)
			npc_collide(actor, 0, dir)
			if (actor.collided == false) then
				actor.y = actor.y + dir
				actor_post_move(actor, 0, dir)
			end
		end
	end
end

function actor_phys(actor, dt)

	--[[ jump
	if actor.spring_force > 0 then
		actor.force_y = -actor.spring_force * 2
		actor.spring_force = 0
	end
	--]]

	-- intents
	if actor.move_x > 0 and actor.force_x < actor.move_x then
		actor.force_x = actor.move_x
	end
	if actor.move_x < 0 and actor.force_x > actor.move_x then
		actor.force_x = actor.move_x
	end

	-- remember if we were "standing"
	local was_standing = actor.standing

	-- reset "standing" flag (will be set during collision)
	actor.standing = 0

	-- same for all similar flags
	actor.bumping_right = 0
	actor.bumping_left = 0
	actor.ledge_right = 0
	actor.ledge_left = 0
	actor.standing_on = nil

-- 2D Game magic:
-- collide X and Y movements separately!
-- this allows "classic" 2D effects like bumping head into ceilings
-- and jumping along walls without having a vector-based collision system
	long_collide(actor, 'x', actor.force_x)
	long_collide(actor, 'y', actor.force_y)

	-- check if we landed, set flag
	if was_standing == 0 and actor.standing == 1 then
		actor.landed = 1 * actor.phys.land_wait
	end

	-- friction
	if actor.force_x < 0 then
		actor.force_x = actor.force_x + 1
		--if actor.force_x > 0 then actor.force_x = 0 end
	elseif actor.force_x > 0 then
		actor.force_x = actor.force_x - 1
		--if actor.force_x < 0 then actor.force_x = 0 end
	end

	-- gravity
	if actor.force_y < 8 then
		actor.force_y = actor.force_y + 1
		--if actor.force_y > 8 then actor.force_y = 8 end
	end

end

function phys_step(dt)
	-- player
	actor_phys(cDoll, physStep)

	--enemies
	local i, doll
	for i, doll in pairs(cLevel.npcs) do

		actor_ai(doll) -- hack: put somewhere else?

		actor_phys(doll)

	end

	--misc
end

function phys_loop(dt)
	local physStep = 1 / capPhysFPS

	cPhysDelay = cPhysDelay + dt

	while (cPhysDelay >= physStep) do

		cPhysDelay = cPhysDelay - physStep

		phys_step(physStep)

	end
end
