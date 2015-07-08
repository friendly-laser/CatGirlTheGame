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

end