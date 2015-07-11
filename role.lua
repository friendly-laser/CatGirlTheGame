roles = {}

function role_load_xml(node)
	local role = {}

	local id, sprite = node.xarg.name, node.xarg.sprite

	role.sprite_id = node.xarg.sprite
	role.phys = { walk_speed = 1, rise_speed = 1, fall_speed = 1, jump_height = 32 }
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
			role.phys.walk_speed = tonumber(sub.xarg.walkspeed) or 1
			role.phys.rise_speed = tonumber(sub.xarg.risespeed) or 1
			role.phys.fall_speed = tonumber(sub.xarg.fallspeed) or 1
			role.phys.jump_height = tonumber(sub.xarg.jumpheight) or 16
			role.phys.land_wait = tonumber(sub.xarg.landwait) or 1
			role.phys.land_speed = tonumber(sub.xarg.landspeed) or 1
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