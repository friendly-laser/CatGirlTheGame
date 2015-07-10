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

ars = {
	{ name = "16:9", w = 480, h = 270 },
	{ name = "4:3", w = 320, h = 240 },
	{ name = "wxga-evil", w = 341.5, h = 192, panx = 1 },
	{ name = "wxga-good", w = 340, h = 192 },
}

function make_resolution(di, dname, win, w, h)
	local res = {}

	res.display = di
	res.display_name = dname
	res.win = win
	res.w = w
	res.h = h

	local i, j
	j = -1
	for i,ar in pairs(ars) do
		if (w % ar.w == 0 and h % ar.h == 0) then
			j = i
			break
		end
	end

	if j == - 1 then return nil end

	ar = ars[j]

	res.ar_name = ar.name

	res.base_w = math.floor(ar.w)
	res.base_h = math.floor(ar.h)
	res.pan_x = ar.panx or 0
	res.pan_y = ar.pany or 0

	res.base_w = res.base_w - res.pan_x
	res.base_h = res.base_h - res.pan_y

	res.scale_x = w / res.base_w
	res.scale_y = h / res.base_h

	return res
end

function find_resolutions()
	local resolutions = {}

	local num_displays = love.window.getDisplayCount()

	mainmenu.num_displays = num_displays

	local i
	for i = 1, num_displays do
		local name = love.window.getDisplayName(i)
		--printf("Display %d: %s\n", i, 	name);

		local w, h = love.window.getDesktopDimensions( i )

		--printf("Desktop dimension: %d,%d\n",w,h);

		local topres = make_resolution(i, name, true, w, h)

		if topres == nil then
			-- hack: make it ourselves, but don't add to list
			topres = {display=i,display_name=name,win=true,w=w,h=h}
		else
			table.insert(resolutions, topres)
		end

		-- try to fit in all ARs
		local j, ar 
		for j, ar in pairs(ars) do

			local s = 1

			while true do

				local test_w = ar.w * s
				local test_h = ar.h * s

				s = s * 2

				if (test_w <= topres.w and test_h <= topres.h) then

					if (test_w == topres.w and test_h == topres.h) then
						break
					end

					table.insert(resolutions, make_resolution(i, name, true, test_w, test_h))

				else
					break
				end

			end

		end

		-- get fullscreen resolutions
		local modes = love.window.getFullscreenModes(i)

		for j,mode in pairs(modes) do

			table.insert(resolutions, make_resolution(i, name, false, mode.width, mode.height))

		end

	end

	-- sort from largest to smallest
	--table.sort(resolutions, function(a, b) return a.w*a.h > b.w*b.h end)

	for i, res in pairs(resolutions) do

		res.label = string.format("%dx%d", res.w, res.h)

		printf("Videmode: %d (%s) -- %dx%d (%s)\n", i,
			trif(res.win==true, "window", "fullscreen"),
			res.w, res.h, res.ar_name);

	end

	return resolutions
end

mainmenu = {}
mainmenu.sel_level = 1
mainmenu.levels = {}
mainmenu.keywait = 0
mainmenu.sel = 1

mainmenu.next_res = 1
mainmenu.fullscreen = false
mainmenu.next_display = 1

function match_res(res, lst)
	if res == nil then return 0,nil end
	lst = lst or cResolutions
	for i,_res in pairs(lst) do
		if 	_res.display == res.display and
			_res.w == res.w and
			_res.h == res.h and
			_res.win == res.win then
			return i,_res
		end
	end
	return 0,nil
end

function res_filter(from, display, win)
	local rmax = 0
	local to = {}
	for i,_res in pairs(cResolutions) do
		if  _res.display == display and
			_res.win == win then

			rmax = rmax + 1
			to[rmax] = _res

		end
	end

	-- sort from largest to smallest
	table.sort(to, function(a, b) return a.w*a.h > b.w*b.h end)

	return rmax, to
end

function menu_res_apply()

	local i, res = match_res(mainmenu.rlist[mainmenu.next_res])

	cRes = res

	cBaseW = res.base_w
	cBaseH = res.base_h
	cScaleW = res.scale_x
	cScaleH = res.scale_y
	cPanX = res.pan_x
	cPanX = res.pan_x

	setWindowMode()

end

function menu_res_refilter()
	mainmenu.rmax, mainmenu.rlist = res_filter(cResolutions, mainmenu.next_display, not(mainmenu.fullscreen))

	if mainmenu.next_res > mainmenu.rmax then
		mainmenu.next_res = 1
	end
end

function menu_res_init(res)
	if res then
		mainmenu.fullscreen = not(res.win)
		mainmenu.next_display = res.display
	end

	mainmenu.rmax, mainmenu.rlist = res_filter(cResolutions, mainmenu.next_display, not(mainmenu.fullscreen))

	local i,_res = match_res(res, mainmenu.rlist)

	if _res then
		mainmenu.next_res = i
	end
end

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


	if self.sel == 4 then
		love.graphics.setColor(0, 255, 0, 255)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end

	love.graphics.print("Display: ", 120, 90)
	love.graphics.print(mainmenu.next_display, 180, 90)

	if self.sel == 5 then
		love.graphics.setColor(0, 255, 0, 255)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end

	love.graphics.print("Resolution: ", 120, 100)
	love.graphics.print(self.rlist[mainmenu.next_res].label, 190, 100)

	if self.sel == 6 then
		love.graphics.setColor(0, 255, 0, 255)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end

	love.graphics.print("Fullscreen: ", 120, 110)
	love.graphics.print(trif(mainmenu.fullscreen,"YES","NO"), 190, 110)

	if self.sel == 7 then
		love.graphics.setColor(0, 255, 0, 255)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end

	love.graphics.print("Apply!", 120, 120)

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

		local mov = 0

		if love.keyboard.isDown("left") then
			mov = -1
		end
		if love.keyboard.isDown("right") then
			mov = 1
		end
		
		if mov ~= 0 then
			if self.sel == 2 then

				self.sel_level = self.sel_level + mov

				if self.sel_level < 1 then self.sel_level = 1 end
				if self.sel_level > table.getn(self.levels) then self.sel_level = table.getn(self.levels) end

			end
			if self.sel == 4 then

				self.next_display = self.next_display + mov

				if self.next_display < 1 then self.next_display = 1 end
				if self.next_display > self.num_displays then self.next_display = self.num_displays end

				menu_res_refilter()

			end
			if self.sel == 6 then

				self.fullscreen = not(self.fullscreen)
				
				menu_res_refilter()			

			end
			if self.sel == 5 then

				self.next_res = self.next_res + mov			

				if self.next_res < 1 then self.next_res = 1 end
				if self.next_res > self.rmax then self.next_res = self.rmax end

			end
		end

		if self.sel < 1 then self.sel = 1 end
		if self.sel > 7 then self.sel = 7		 end

		if love.keyboard.isDown("return") then
			if self.sel == 3 then
				love.event.quit()
			end
			if self.sel == 7 then
				menu_res_apply()
			end
			if self.sel == 1 then
				start_game()
			end
		end

	end

end

function start_game()

	restart_level(mainmenu.levels[mainmenu.sel_level])

	loveHandler = game

end

