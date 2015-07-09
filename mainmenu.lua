function load_levels()

	local dir = "Levels"
	--assuming that our path is full of lovely files (it should at least contain main.lua in this case)
	local files = love.filesystem.getDirectoryItems(dir)
	local i = 1
	for k, file in ipairs(files) do
		if string.ends(file, ".tmx") then
			print(i .. " (" .. k .. "). " .. file) --outputs something like "1. main.lua"
			mainmenu.levels[i] = file
			i = i + 1
		end
	end

end

mainmenu = {}
mainmenu.sel_level = 1
mainmenu.levels = {}
mainmenu.keywait = 0
mainmenu.sel = 1
function mainmenu:draw()

	love.graphics.print("CatGirl!", 0, 0)

	if self.sel == 1 then
		love.graphics.setColor(0, 255, 0, 255)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end

	love.graphics.print("Start!", 120, 50)

	if self.sel == 2 then
		love.graphics.setColor(0, 255, 0, 255)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end

	love.graphics.print("Level: ", 120, 60)
	love.graphics.print(mainmenu.levels[mainmenu.sel_level], 160, 60)

	if self.sel == 3 then
		love.graphics.setColor(0, 255, 0, 255)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end

	love.graphics.print("Quit! ", 120, 70)

	love.graphics.setColor(255, 255, 255, 255)
end

function mainmenu:update(dt)

	self.keywait = self.keywait - dt
	if self.keywait <= 0 then

		self.keywait = 0.1

		if love.keyboard.isDown("down") then

			self.sel = self.sel + 1

		end
		if love.keyboard.isDown("up") then

			self.sel = self.sel - 1

		end
		
		if love.keyboard.isDown("left") then
			self.sel_level = self.sel_level - 1
		end
		if love.keyboard.isDown("right") then
			self.sel_level = self.sel_level + 1
		end

		if self.sel < 1 then self.sel = 1 end
		if self.sel > 3 then self.sel = 3 end

		if self.sel_level < 1 then self.sel_level = 1 end
		if self.sel_level > table.getn(self.levels) then self.sel_level = table.getn(self.levels) end


		if love.keyboard.isDown("return") then
			if self.sel == 3 then
				love.event.quit()
			else
				start_game()
			end
		end
		
	end

end

function start_game()
	
	restart_level(mainmenu.levels[mainmenu.sel_level])
	
	loveHandler = game
end

