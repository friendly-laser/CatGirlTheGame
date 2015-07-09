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

	actor.walk_speed = 2
	actor.air_speed = 1

	actor.force_x = 0
	actor.force_y = 0
	actor.spring = 0
	actor.spring_force = 0
	actor.standing = 0

	return actor
end

function actor_apply_anim(actor, dt)

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

	if actor.standing == 0 then
		--if actor.force_y < 0 then
			actor.frame = 3
		--else
			--actor.frame = 4
		--end
	end

end