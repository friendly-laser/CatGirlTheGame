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

function actor_apply_anim(actor, dt)

	--update effects
	if (actor.effect ~= "") then
		actor.effect_delay = actor.effect_delay - dt

		if actor.effect_delay <= 0 then
			actor.effect_delay = 0
			actor.effect = ""
		end
	end

	local anim

	-- select animation
	if actor.standing == 1 then
		if actor.move_x ~= 0 then
			-- moving on the ground
			anim = "walk"
		else
			-- standing on the ground
			anim = "idle"
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

	--update misc.
	actor.landed = actor.landed - dt
	if actor.landed < 0 then actor.landed = 0 end
	actor.think_delay = actor.think_delay - dt
	if actor.think_delay < 0 then actor.think_delay = 0 end
	actor.ai_delay = actor.ai_delay - dt
	if actor.ai_delay < 0 then actor.ai_delay = 0 end

	--move to next frame
	actor.anim_delay = actor.anim_delay - dt

	if actor.anim_delay <= 0 then
		actor.frame = actor.frame + 1
	end

	if actor.frame > actor.sprite['max_frames'][actor.anim] then
		actor.frame = 1
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

	local x_factor = vpad.report['x']
	local move_speed = actor.phys.walk_speed

	if actor.standing == 0 then
		if actor.force_y < 0 then
			move_speed = actor.phys.rise_speed
		else
			move_speed = actor.phys.fall_speed
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

	actor.spring_jump = actor.spring_jump + vpad.report['jump']
	if (actor.spring_jump > 1) then actor.spring_jump = 1 end

	if actor.spring_jump > 0 then
		if actor.standing == 1 then
			actor.force_y = -round(actor.spring_jump * actor.phys.jump_height)
			actor.spring_jump = 0
		elseif vpad.imps[1].point == 0 then
			-- hack: XXX
			actor.spring_jump = 0
		end
	end

	vpad:clear()

end

function actor_post_move(actor, dx, dy)

	if cDoll.standing_on == actor then

		cDoll.force_x = cDoll.force_x + dx
		cDoll.force_y = cDoll.force_y + dy

	end

end
