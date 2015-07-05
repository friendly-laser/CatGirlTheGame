
function doll_control(actor, dt)

	actor.anim_delay = actor.anim_delay - dt
	actor.anim = 'idle'
	actor.force_x = 0

	if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
		actor.force_x = 1
		actor.flip = 1
		actor.anim = 'walk'
	elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
		actor.force_x = -1
		actor.flip = -1
		actor.anim = 'walk'
	end

	if love.keyboard.isDown(" ") then
		if actor.standing == 1 then
			actor.spring = actor.spring + 1
		end
	end

	if not(love.keyboard.isDown(" ")) or actor.spring > 8 then
		if actor.spring > 0 then
			actor.spring_force = actor.spring
			actor.spring = 0
		end
	end

	if actor.anim_delay <= 0 then
		actor.anim_delay = 0.1000
		actor.frame = actor.frame + 1
	end

	if actor.frame > actor.sprite['max_frames'][actor.anim] then
		actor.frame = 1
	end

end