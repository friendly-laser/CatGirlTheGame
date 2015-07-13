roles = {}

function role_load_xml(node)
	local role = {}

	local id, sprite = node.xarg.name, node.xarg.sprite

	role.sprite_id = node.xarg.sprite
	role.walkspeed = { walk = 1, jump = 1, rise = 1, fall = 1, land = 1 }
	role.phys = { jump_height = 16, jump_wait = 1.0, land_wait = 1.0,
	walk_attack=1,walk_release=1,walk_gain=1,walk_gain_knee=0.4 }
	role.ai = { type = "none" }
	role.box = { collide = "none", hit = "none" }

	for a, sub in ipairs(node) do
		if (sub.label == "box") then
			role.box.collide = sub.xarg.collide or "none"
			role.box.hit = sub.xarg.hit or "none"
		end
		if (sub.label == "ai") then
			role.ai.type = sub.xarg.type or "none"
			role.ai.ledge = sub.xarg.ledge or "ignore"
			role.ai.think_delay = tonumber(sub.xarg.thinkdelay) or 0
			role.ai.think_duration = tonumber(sub.xarg.thinkduration) or 0
			role.ai.think_chance = tonumber(sub.xarg.thinkchance) or 0
		end
		if (sub.label == "phys") then
			role.phys.jump_height = tonumber(sub.xarg.jumpheight) or 16
			role.phys.land_wait = tonumber(sub.xarg.landwait) or 1
			role.phys.gravity = tonumber(sub.xarg.gravity) or 1
			role.phys.friction = tonumber(sub.xarg.friction) or 1
		end
		if (sub.label == "walkcontrol") then
			role.phys.walk_attack = tonumber(sub.xarg.attack) or 1
			role.phys.walk_release = tonumber(sub.xarg.release) or 1
			role.phys.walk_gain = tonumber(sub.xarg.gain) or 1
			role.phys.walk_gain_knee = tonumber(sub.xarg.gainknee) or 0.4
		end
		if (sub.label == "jumpcontrol") then
			role.phys.jump_attack = tonumber(sub.xarg.attack) or 1
			role.phys.jump_release = tonumber(sub.xarg.release) or 1
			role.phys.jump_gain = tonumber(sub.xarg.gain) or 1
			role.phys.jump_gain_knee = tonumber(sub.xarg.gainknee) or 0.4
		end
		if (sub.label == "walkspeed") then
			local name, default
			for name, default in pairs(role.walkspeed) do
				role.walkspeed[name] = tonumber(sub.xarg[name]) or default
			end
		end
	end

	roles[id] = role

	return role
end

function roles_parse_xml(filename)
    local xml = LoadXML(love.filesystem.read(filename))
	local root = xml[2]
	if root.label == "role" then
		role_load_xml(root)
	end
	if root.label == "roles" then
		for a, node in ipairs(root) do
			role_load_xml(node)
		end
	end
end