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
	if not(cGamepad == nil) and cGamepad.isConnected == true then
		printf("Doing gamepad...\n");
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
