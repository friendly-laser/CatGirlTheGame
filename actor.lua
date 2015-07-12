Actor = {}
Actor.__index = Actor

function make_actor(role_id, x, y, sprite_id)
	local actor = {}
	setmetatable(actor, Actor)

	actor.x = x
	actor.y = y

	actor:setRole(role_id)
	actor:setSprite(sprite_id or actor.sprite_id)

	actor.anim = 'idle'
	actor.frame = 1
	actor.flip = 1
	actor.anim_delay = 0

	actor.force_x = 0
	actor.force_y = 0
	actor.move_x = 0
	actor.spring_jump = 0
	actor.landed = 0
	actor.ledge_right = 0
	actor.ledge_left = 0
	actor.standing_on = nil
	actor.standing = 0

	actor.effect = ""
	actor.effect_delay = 0

	actor.think_delay = 0
	actor.ai_delay = 0

	return actor
end

function Actor:setRole(role_id)
	if not(roles[role_id]) then
		printf("Undefined role %s !!! \n", role_id)
		return
	end
	self.role_id = role_id
	self.sprite_id = roles[role_id].sprite_id
	self.walkspeed = roles[role_id].walkspeed
	self.phys = roles[role_id].phys
	self.collide = roles[role_id].box.collide
	self.hit = roles[role_id].box.hit
	self.ai = roles[role_id].ai
end

function Actor:setSprite(sprite_id)
	if not(sprites[sprite_id]) then
		printf("Undefined sprite %s !!! \n", sprite_id)
		return
	end
	self.sprite_id = sprite_id
	self.sprite = sprites[sprite_id]
	self.w = self.sprite['frame_w']
	self.h = self.sprite['frame_h']
end

function Actor:getAABB(dx, dy)
	dx = dx or 0
	dy = dy or 0
	return {
		x = self.sprite.bound_x + self.x + dx,
		y = self.sprite.bound_y + self.y + dy,
		w = self.sprite.bound_w,
		h = self.sprite.bound_h,
	}
end

function Actor:update(dt)
--update effects
	if (self.effect ~= "") then
		self.effect_delay = self.effect_delay - dt

		if self.effect_delay <= 0 then
			self.effect_delay = 0
			self.effect = ""
		end
	end
--update misc.
	self.landed = self.landed - dt
	if self.landed < 0 then self.landed = 0 end
	self.think_delay = self.think_delay - dt
	if self.think_delay < 0 then self.think_delay = 0 end
	self.ai_delay = self.ai_delay - dt
	if self.ai_delay < 0 then self.ai_delay = 0 end	
end

function actor_apply_anim(actor, dt)

	actor:update(dt)

	local anim

	-- select animation
	if actor.standing == 1 then
		if actor.spring ~= 0 then
			--preparing to jump
			anim = "jump"
		else
			if actor.landed > 0 then
				-- just landed
				anim = "land"
			else
				if actor.move_x ~= 0 then
					-- moving on the ground
					anim = "walk"
				else
					-- standing on the ground
					anim = "idle"
				end
			end
		end
	else
		if actor.force_y < 0 then
			--rising
			if actor.force_x ~= 0 then
				--rising sideways
				anim = "rise"
			else
				--rising vertically
				anim = "vrise"
			end
		else
			--falling
			anim = "fall"
		end
	end

	-- change animation
	if actor.anim ~= anim then
		--printf("Setting anim `%s` (was %s), frame=%d\n", anim, actor.anim, 1)
		actor.anim = anim
		actor.frame = 1
		actor.anim_delay = actor.sprite['delays'][actor.anim][actor.frame]
	end

	-- speedup/slowdown walking animation by move speed
	if actor.anim == "walk" then
		local walk_abs = math.abs(actor.force_x)
		if walk_abs > 4 then
			dt = dt * 2
		end
		if walk_abs > 8 then
			dt = dt * 2
		end
	end

	--move to next frame
	actor.anim_delay = actor.anim_delay - dt

	if actor.anim_delay <= 0 then
		actor.frame = actor.frame + 1
	end

	if actor.frame > actor.sprite['max_frames'][actor.anim] then
		actor.frame = actor.sprite['reframe'][actor.anim]
	end

	if actor.anim_delay <= 0 then
		actor.anim_delay = actor.sprite['delays'][actor.anim][actor.frame]
	end

end

function actor_damage(actor, dmg)

	actor.effect = "flicker"
	actor.effect_delay = 2

end

function actor_apply_control(actor, vpad)

	local move_speed = actor.walkspeed.walk

	-- hack: apply something back
	vpad.ref.jump:setSpeed(actor.phys.jump_wait)

	if actor.standing == 0 then
		if actor.force_y < 0 then
			move_speed = actor.walkspeed.rise
		else
			move_speed = actor.walkspeed.fall
		end
	else
		if actor.spring > 0 then
			move_speed = actor.walkspeed.jump
		end
		if actor.landed > 0 then
			move_speed = actor.walkspeed.land
		end
	end

	actor.move_x = 0

	if vpad.report['x'] > 0 then
		local x_factor = math.floor(vpad.report['x'] * move_speed)
		if x_factor == 0 then x_factor = 1 end
		actor.move_x = x_factor
		actor.flip = 1
	elseif vpad.report['x'] < 0 then
		local x_factor = math.ceil(vpad.report['x'] * move_speed)
		if x_factor == 0 then x_factor = -1 end
		actor.move_x = x_factor
		actor.flip = -1
	end

	actor.spring = vpad.ref.jump.ball

	actor.spring_jump = actor.spring_jump + vpad.report['jump']
	if (actor.spring_jump > 1) then actor.spring_jump = 1 end

	if actor.spring_jump > 0 then
		if actor.standing == 1 then
			actor.force_y = -round(actor.spring_jump * actor.phys.jump_height)
			actor.spring_jump = 0
		elseif vpad.ref.jump.point == 0 then
			-- hack: XXX
			actor.spring_jump = 0
		end
	end

	vpad:clear()

end

function actor_ai(actor)

	-- Not an AI!
	if actor.ai.type == "none" then
		return
	end

	-- Turn around
	if actor.bumping_right == 1 then

		actor.flip = -1

	elseif actor.bumping_left == 1 then

		actor.flip = 1

	end

	-- Turn around on platform edges
	if actor.ai.ledge == "avoid" and actor.standing == 1 then
	if actor.ledge_right == 1 then

		actor.flip = -1

	elseif actor.ledge_left == 1 then

		actor.flip = 1

	end
	end

	-- Stop and think
	if actor.ai.think_chance > 0 then

		if actor.think_delay == 0 then

			actor.think_delay = actor.ai.think_delay

			if math.random(1,100) < actor.ai.think_chance then
				actor.ai_delay = actor.ai.think_duration
				if math.random(1,100) < actor.ai.think_chance then
					actor.flip = -actor.flip
				end
			end

		end

		if actor.ai_delay > 0 then
			actor.move_x = 0
			return
		end

	end

	actor.move_x = actor.flip * actor.walkspeed.walk

end

function Actor:moveTo(nx, ny)
	local dx, dy
	dx = nx - self.x
	dy = ny - self.y
	self.x = nx
	self.y = ny
	self:onMove(dx, dy)
end

function Actor:moveBy(dx, dy)
	self.x = self.x + dx
	self.y = self.y + dy
	self:onMove(dx, dy)
end

function Actor:onMove(dx, dy)

	if cDoll.standing_on == self then

		cDoll.force_x = cDoll.force_x + dx
		cDoll.force_y = cDoll.force_y + dy

	end

end

-- improtant: hit "event" handler
function Actor:onHit(actor, hit, dx,  dy, htype, arg1, arg2)
	if (hit == "bounce") then
		actor.force_y = -20
	end
	if (hit == "damage" and actor.effect == "") then
		actor.force_y = -15
		actor.force_x = -15 * actor.flip
		actor_damage(actor, 1);
	end
	if (htype == "object" and not(arg1.taken)) then
		local obj = arg1
		obj.visible = 0
		obj.taken = true
		play_sound("coin2")
	end
end
