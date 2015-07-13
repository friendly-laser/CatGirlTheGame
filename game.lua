game = {}

function game:draw()

	-- Push camera tranform
	camera:set()

	-- DRAW
	draw_frame()

	-- Pop camera transform
	camera:unset()

	love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 0, 0)
	love.graphics.print("girl: "..cDoll.role_id, 0, 10)	
end

function game:update(dt)

	if love.keyboard.isDown("escape") then
		abort_game()
		return
	end

--	doll:control()
--	doll:update(dt)
--	doll:apply(cDoll)

	actor_apply_control(cDoll, vpad)

	phys_loop(dt)

	local i, doll
	for i, doll in pairs(cLevel.npcs) do
		actor_apply_anim(doll, dt)
	end

	actor_apply_anim(cDoll, dt)

	camera:follow(cDoll)

	anim_all_tiles(dt)

	anim_objects(dt)
end