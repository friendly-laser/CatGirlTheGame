function tiles_around_actor(level, actor)
	local atx = math.floor(actor.x / level.tileW)
	local aty = math.floor(actor.y / level.tileH)

	local atw = math.floor((actor.x+actor.w) / level.tileW)
	local ath = math.floor((actor.y+actor.h) / level.tileH)

	atx = atx - 1
	aty = aty - 1
	atw = atw + 1
	ath = ath + 1

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
	return box1.x < box2.x + box2.w and
		box2.x < box1.x + box1.w and
		box1.y < box2.y + box2.h and
		box2.y < box1.y + box1.h
end
function box_above_box(box1, box2)
	return box1.y + box1.h <= box2.y + 1
end
function box_leftof_box(box1, box2)

end
function box_rightof_box(box1, box2)

end

function tile_collide(actor, dx, dy)
	local level = cLevel
	local tilesets = cLevel.tilesets

-- Try moving
	local new_x, new_y

	new_x = actor.x + dx
	new_y = actor.y + dy

-- Collide with tiles
	local tx,ty,tw,th = tiles_around_actor(level, actor);

	for j = ty, th do
		for i = tx, tw do

			local tileid = level.tilemap[j][i]
			local x = (i-1) * level.tileW
			local y = (j-1) * level.tileH

			local mode = tilesets[level.tileset_id]['collide'][tileid]

			local actor_box = {}
			actor_box.x = new_x - actor.sprite.origin_x + actor.sprite.bound_x
			actor_box.y = new_y + actor.sprite.bound_y
			actor_box.w = actor.sprite.bound_w
			actor_box.h = actor.sprite.bound_h

			local tile_box = {}
			tile_box.x = x
			tile_box.y = y
			tile_box.w = level.tileW
			tile_box.h = level.tileH

			local collided = false

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
			
			if collided == true then
				new_x = actor.x
				new_y = actor.y
				if (dy > 0) then
					actor.standing = 1
				end
			end
		end
	end

	actor.x = new_x
	actor.y = new_y
end

function long_collide(actor, mode, dm)
	local dir = 1
	local amnt = 1

	if dm == 0 then return end

	amnt = math.abs(dm)
	if dm < 0 then dir = -1 else dir = 1 end

	if amnt > 4 then amnt = 4 end

	if mode == 'x' then
		for i = 1, amnt do
			tile_collide(actor, dir, 0)
		end
	end
	if mode == 'y' then
		for i = 1, amnt do
			tile_collide(actor, 0, dir)
		end
	end
end

function actor_phys(actor, dt)

	-- jump
	if actor.spring_force > 0 then
		actor.force_y = -actor.spring_force * 2
		actor.spring_force = 0
	end

	-- gravity
	if actor.force_y < 8 then
		actor.force_y = actor.force_y + 1
	end

	-- reset "standing" flag (will be set during collision)
	actor.standing = 0

-- 2D Game magic:
-- collide X and Y movements separately!
-- this allows "classic" 2D effects like bumping head into ceilings
-- and jumping along walls without having a vector-based collision system
	long_collide(actor, 'x', actor.force_x)
	long_collide(actor, 'y', actor.force_y)
end

function phys_step(dt)
	-- player
	actor_phys(cDoll, physStep)

	--enemies

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
