VAxis = {}
VAxis.__index = VAxis

function VAxis.create(name)
	local vax = {}
	setmetatable(vax, VAxis)

	vax.name = name
	vax.point = 0 -- intent
	vax.ball = 0 -- current

	vax.kbd_pull1 = nil -- keyboard key A (1)
	vax.kbd_pull2 = nil -- keyboard key A (2)
	vax.kbd_push1 = nil -- keyboard key B (1)
	vax.kbd_push2 = nil -- keyboard key B (2)

	vax.joy_pull1 = nil -- joystick key A (1)
	vax.joy_push1 = nil -- joystick key B (1)
	vax.joy_axis = nil  -- joystick axis

	vax.attack = 2  -- regular speed
	vax.release = 4 -- back-to-zero speed
	vax.gain = 4    -- regular speed, accellerating
	vax.gain_knee = 0.4 -- apply gain if we haven't passed the knee

	return vax
end

function VAxis:setSpeed(attack, release, gain, gain_knee)
	attack = attack or 1
	release = release or attack
	gain = gain or release
	gain_knee = gain_knee or 0.4

	self.attack = attack
	self.release = release
	self.gain = gain
	self.gain_knee = gain_knee
end

function VAxis:setPullKey(kbd1, kbd2)
	self.kbd_pull1 = kbd1
	self.kbd_pull2 = kbd2
end
function VAxis:setPushKey(kbd1, kbd2)
	self.kbd_push1 = kbd1
	self.kbd_push2 = kbd2
end
function VAxis:setPullButton(btn1, btn2)
	self.joy_pull1 = btn1
	self.joy_pull2 = btn2
end
function VAxis:setPushButton(btn1, btn2)
	self.joy_push1 = btn1
	self.joy_push2 = btn2
end
function VAxis:setJoystickAxis(jax)
	self.joy_axis = jax
end

function VAxis:update(dt)

	local dir = 1
	local speed = self.attack

	if self.ball ~= self.point then

		if (self.ball > self.point) then dir = -1 end

		if self.point == 0 then

			speed = self.release

		else
			local ball_gain = math.abs(self.ball)

			if (self.ball > 0 and self.point < 0) or
			   (self.ball < 0 and self.point > 0) then
			-- drift
			-- drift: quick
				self.ball = 0
			end

			if ball_gain < self.gain_knee then -- formularize?
				speed = self.gain
			end
		end

		self.ball = self.ball + dir * speed * dt

		if (self.point == 0 and dir == 1 and self.ball > 0) then self.ball = 0 end
		if (self.point == 0 and dir ==-1 and self.ball < 0) then self.ball = 0 end

		if (self.ball > 1) then self.ball = 1 end
		if (self.ball <-1) then self.ball =-1 end

	end

	vpad.report[self.name] = self.ball

end


VImpulse = {}
VImpulse.__index = VImpulse

function VImpulse.create(name)
	local vimp = {}
	setmetatable(vimp, VImpulse)

	vimp.name = name
	vimp.point = 0 -- holding down
	vimp.ball = 0 -- push progress

	vimp.kbd_push1 = nil -- keyboard key A (1)
	vimp.kbd_push2 = nil -- keyboard key A (2)

	vimp.attack = 2  -- regular speed
	vimp.gain = 4    -- accelerate speed

	return vimp
end

function VImpulse:setKey(kbd1, kbd2)
	self.kbd_push1 = kbd1
	self.kbd_push2 = kbd2
end
function VImpulse:setButton(btn1, btn2)
	self.joy_push1 = btn1
	self.joy_push2 = btn2
end
function VImpulse:setJoystickAxis(jax)
	self.joy_axis = jax
end

function VImpulse:setSpeed(attack, release, gain)
	attack = attack or 1
	release = release or attack
	gain = gain or release

	self.attack = attack
	self.release = release
	self.gain = gain
end


function VImpulse:control()

end
function VImpulse:update(dt)
	local dir = 1
	local speed = self.attack

	if self.point == 0 then

		if self.ball ~= 0 then

			vpad.report[self.name] = self.ball
			self.ball = 0

		end

	else

		local ball_gain = math.abs(self.ball)

		if ball_gain > 0.4 then -- formularize?
			speed = self.gain
		end

		self.ball = self.ball + dir * speed * dt

		if (self.ball > 1) then self.ball = 1 end

		if (self.ball == self.point) then

			vpad.report[self.name] = self.ball
			self.ball = 0

		end

	end

end

vpad = {}
vpad.joystick = nil -- active gamepad or nil
vpad.report = {} -- current state of affairs
vpad.ref = {} -- table of all virtual things by name
vpad.axs = {} -- list of Virtual Axies
vpad.imps = {} -- list of Virtual Impulses

function vpad:create_axis(name)
	vax = VAxis.create(name)
	table.insert(self.axs, vax)
	self.report[name] = 0
	self.ref[name] = vax
	return vax
end
function vpad:create_impulse(name)
	vimp = VImpulse.create(name)
	table.insert(self.imps, vimp)
	self.report[name] = 0
	self.ref[name] = vimp
	return vimp
end

function vpad:init_generic()
	local ax,btn

	ax = vpad:create_axis("x")
	ax:setPullKey("left", "a")
	ax:setPushKey("right", "d")
	ax:setJoystickAxis("leftx")

	btn = vpad:create_impulse("jump")
	btn:setKey(" ", "return")
	btn:setButton("a")
	--btn:setJoystickAxis("triggerright")

--hat
	local hat_speed = 4
	btn = vpad:create_impulse("up")
	btn:setKey("up", "w")
	btn:setButton("dpup")
	btn:setSpeed(hat_speed, hat_speed, hat_speed*4)

	btn = vpad:create_impulse("down")
	btn:setKey("down", "s")
	btn:setButton("dpdown")
	btn:setSpeed(hat_speed, hat_speed, hat_speed*4)

	btn = vpad:create_impulse("left")
	btn:setKey("left", "a")
	btn:setButton("dpleft")
	btn:setSpeed(hat_speed, hat_speed, hat_speed*4)

	btn = vpad:create_impulse("right")
	btn:setKey("right", "d")
	btn:setButton("dpright")
	btn:setSpeed(hat_speed, hat_speed, hat_speed*4)
end

function vpad:setJoystick(joy)
	self.joystick = joy
end

function vpad:control()
	local i,vax,vimp
	local func_isDown = love.keyboard.isDown
	local func_joyDown
	func_joyDown = function()
		return false
	end
	local joy_on = false

	if self.joystick ~= nil and self.joystick:isConnected() == true then
		joy_on = true
		func_joyDown = function(b) if b == nil then return false else return self.joystick:isGamepadDown(b) end end
	end

	for i,vax in pairs(self.axs) do

		vax.point = 0

		if func_isDown(vax.kbd_push1) or func_isDown(vax.kbd_push2) then
			vax.point = 1
		elseif func_isDown(vax.kbd_pull1) or func_isDown(vax.kbd_pull2) then
			vax.point = -1
		end
		if vax.joy_axis and joy_on == true then
			vax.point = self.joystick:getGamepadAxis(vax.joy_axis)
		end

	end

	for i,vimp in pairs(self.imps) do

		vimp.point = 0

		if func_isDown(vimp.kbd_push1) or func_isDown(vimp.kbd_push2) then
			vimp.point = 1
		end
		if func_joyDown(vimp.joy_push1) or func_joyDown(vimp.joy_push2) then
			vimp.point = 1
		end
		if vimp.joy_axis and joy_on == true then
			vimp.point = self.joystick:getGamepadAxis(vimp.joy_axis)
		end

	end

end

function vpad:clear()
	for name,val in pairs(self.report) do
		self.report[name] = 0
	end
end

function vpad:update(dt)
	local i,vax,vimp

	for i,vax in pairs(self.axs) do

		vax:update(dt)

	end
	for i,vimp in pairs(self.imps) do

		vimp:update(dt)

	end
end

function vpad:draw()

	local bx = 0
	local by = 20

	for i,vax in pairs(self.axs) do

		local radii = 5
		local diam = 10
		local len = 100

		love.graphics.setColor(255,255,255,255)

		love.graphics.print(vax.name, bx + 2, by)
		by = by + 20

		love.graphics.rectangle("line", bx, by, diam, 100)

		local ball_pos = vax.ball * 50 + 50
		local point_pos = vax.point * 50 + 50

		love.graphics.setColor(255,127,255,255)
		--love.graphics.rectangle("fill", bx, by + point_pos - radii, diam, diam)
		love.graphics.circle("fill", bx + radii, by + point_pos, radii, 10)

		love.graphics.setColor(255,0,255,255)
		--love.graphics.rectangle("fill", bx, by + ball_pos - radii, diam, diam)
		love.graphics.circle("fill", bx + radii, by + ball_pos, radii, 10)

		local report = string.format("%.2f", vpad.report[vax.name])

		love.graphics.setColor(trif(vpad.report[vax.name]==0,255,0),trif(vpad.report[vax.name]==0,0,255),0,255)
		love.graphics.rectangle("line", bx, by + len + radii, diam * 3, diam + radii)
		love.graphics.print(report, bx + 2, by + len + radii)

		bx = bx + diam * 4
		by = by - 20

	end

	for i,vimp in pairs(self.imps) do

		local radii = 5
		local diam = 10
		local len = 100

		--decor
		love.graphics.setColor(255,255,255,255)
		love.graphics.print(vimp.name, bx + 2, by)
		by = by + 20

		love.graphics.rectangle("line", bx, by, diam, len)

		--status
		local ball_pos = vimp.ball * len
		local point_pos = vimp.point * len

		love.graphics.setColor(255,127,255,255)
		--love.graphics.rectangle("fill", bx, by + point_pos - radii, diam, diam)
		love.graphics.circle("fill", bx + radii, by + point_pos, radii, 10)

		love.graphics.setColor(255,0,255,255)
		--love.graphics.rectangle("fill", bx, by + ball_pos - radii, diam, diam)
		love.graphics.circle("fill", bx + radii, by + ball_pos, radii, 10)

		--report
		local report = string.format("%.2f", vpad.report[vimp.name])

		love.graphics.setColor(trif(vpad.report[vimp.name] == 0,255,0),trif(vpad.report[vimp.name] == 0,0,255),0,255)
		love.graphics.rectangle("line", bx, by + len + radii, diam * 3, diam + radii)
		love.graphics.print(report, bx + 2, by + len + radii)

		bx = bx + diam * 4
		by = by - 20
	end

	love.graphics.setColor(255,255,255,255)
end



doll = {}
doll.spring_cap = 4
doll.spring_max = 16
doll.intent_x = 0
doll.intent_y = 0
doll.ball_x = 0
doll.ball_y = 0
doll.intent_spring = 0
doll.spring = 0
doll.spring_release = 0

function doll:control()

	self.intent_x = 0
	self.intent_y = 0

--keyboard
	if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
		self.intent_x = 1
	elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
		self.intent_x = -1
	end

	if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
		self.intent_y = -1
	elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
		self.intent_y = 1
	end

	if love.keyboard.isDown(" ") then
		self.intent_spring = 1
	else
		self.intent_spring = 0
	end

--gamepad
	if cGamepad ~= nil and cGamepad:isConnected() == true then
		-- getGamepadAxis returns a value between -1 and 1.
		-- It returns 0 when it is at rest

		self.intent_x = cGamepad:getGamepadAxis("leftx")
		self.intent_y = cGamepad:getGamepadAxis("lefty")

		if cGamepad:isGamepadDown("a") then
			self.intent_spring = 1
		else
			self.intent_spring = 0
		end
	end
end

function doll:update(dt)

	local move_speed = 1
	local spring_speed = 30

	if self.intent_x == 0 then
		move_speed = move_speed * 4
	elseif self.ball_x > 0 and self.intent_x < 0 then
		self.ball_x = 0
	elseif self.ball_x < 0 and self.intent_x > 0 then
		self.ball_x = 0
	end

	if self.ball_x < self.intent_x then

		if self.ball_x > 0.4 then
			move_speed = move_speed * 2
		end

		self.ball_x = self.ball_x + move_speed * dt

		if self.ball_x > self.intent_x then
			self.ball_x = self.intent_x
		end

	end
	if self.ball_x > self.intent_x then

		if self.ball_x < -0.4 then
			move_speed = move_speed * 2
		end

		self.ball_x = self.ball_x - move_speed * dt

		if self.ball_x < self.intent_x then
			self.ball_x = self.intent_x
		end

	end

	if self.intent_spring == 1 and self.spring_release == 0 then
		self.spring = self.spring + spring_speed * dt
	end

	if self.intent_spring == 0 or self.spring >= self.spring_cap then
		if self.spring > self.spring_cap then
			self.spring = self.spring_cap
		end
		if self.spring > 0 then
			local spring_factor = self.spring / self.spring_cap
			--printf("Released spring: %f, factor: %f\n", self.spring, spring_factor)
			self.spring_release = round(spring_factor * self.spring_max)
			self.spring = 0
			if spring_factor > 0 and self.spring_release < 1 then
				self.spring_release = 1
			end
		end
	end

end

function doll:apply(actor)

	actor.force_x = 0
	--actor.anim = 'idle'

	local x_factor = self.ball_x
	local move_speed = actor.walk_speed

	if actor.standing == 0 then
		move_speed = actor.air_speed
	end

	if self.ball_x > 0 then
		actor.force_x = math.floor(x_factor * move_speed)
		if actor.force_x == 0 then actor.force_x = 1 end
		actor.flip = 1
		--actor.anim = 'walk'
	elseif self.ball_x < 0 then
		actor.force_x = math.ceil(x_factor * move_speed)
		if actor.force_x == 0 then actor.force_x = -1 end
		actor.flip = -1
		--actor.anim = 'walk'
	end

	if self.spring_release > 0 then
		if actor.standing == 1 then
			actor.force_y = -self.spring_release
			self.spring_release = 0
		else
			-- note: this makes quake-style jumping impossible:
			-- todo: improve to allow both that and bug-free jumping
			self.spring_release = 0
		end
	end

end
