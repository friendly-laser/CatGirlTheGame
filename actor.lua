function make_actor(sprite_id, x, y)
	local actor = {}

	actor.sprite_id = sprite_id
	actor.sprite = sprites[sprite_id]
	actor.x = x
	actor.y = y

	actor.w = actor.sprite['frame_w']
	actor.h = actor.sprite['frame_h']

	actor.anim = 'idle'
	actor.frame = 1
	actor.flip = 1
	actor.anim_delay = 0

	actor.walk_speed = 5
	actor.air_speed = 4

	actor.force_x = 0
	actor.force_y = 0
	actor.spring = 0
	actor.spring_force = 0
	actor.standing = 0

	actor.effect = ""
	actor.effect_delay = 0

	return actor
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
		if actor.force_x ~= 0 then
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
		if walk_abs < 1 then
			dt = dt / 4
		end
	end

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
