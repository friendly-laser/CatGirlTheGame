--camera module
--based on http://nova-fusion.com/2011/04/19/cameras-in-love2d-part-1-the-basics/

camera = {}
camera.x = 0
camera.y = 0
camera.scaleX = 1
camera.scaleY = 1
camera.rotation = 0

function camera:set()
  love.graphics.push()
  love.graphics.rotate(-self.rotation)
  love.graphics.scale(1 / self.scaleX, 1 / self.scaleY)
  love.graphics.translate(-self.x, -self.y)
end

function camera:unset()
  love.graphics.pop()
end

function camera:getTileBounds()
	local level = cLevel

	self.w = love.graphics.getWidth()
	self.h = love.graphics.getHeight()

	return tiles_around_actor(level, camera)
end

function camera:follow(actor)
	--calc
	local w = love.graphics.getWidth() / cScaleW
	local h = love.graphics.getHeight() / cScaleH

	local x = actor.x - w / 2
	local y = actor.y - h / 2

	local max_w = cLevel.cols * cTileW
	local max_h = cLevel.rows * cTileH

	-- clamp
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	if x + w > max_w then x = max_w - w end
	if y + h > max_h then y = max_h - h end

	-- set
	self:setPosition(x, y)
end

function camera:move(dx, dy)
  self.x = self.x + (dx or 0)
  self.y = self.y + (dy or 0)
end

function camera:rotate(dr)
  self.rotation = self.rotation + dr
end

function camera:scale(sx, sy)
  sx = sx or 1
  self.scaleX = self.scaleX * sx
  self.scaleY = self.scaleY * (sy or sx)
end

function camera:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
end

function camera:setScale(sx, sy)
  self.scaleX = sx or self.scaleX
  self.scaleY = sy or self.scaleY
end
