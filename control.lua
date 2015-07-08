
function doll_control(actor, dt)

	actor.anim = 'idle'
	actor.force_x = 0

	if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
		actor.force_x = 2
		actor.flip = 1
		actor.anim = 'walk'
	elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
		actor.force_x = -2
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

end
