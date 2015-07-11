-- see https://love2d.org/wiki/TiledMapLoader for latest version
-- loader for "tiled" map editor maps (.tmx,xml-based) http://www.mapeditor.org/
-- supports multiple layers
 
-- ***** ***** ***** ***** ***** xml parser
 
-- LoadXML from http://lua-users.org/wiki/LuaXml
function LoadXML(s)
  local function LoadXML_parseargs(s)
    local arg = {}
    string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
    end)
    return arg
  end
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=LoadXML_parseargs(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=LoadXML_parseargs(xarg)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[stack.n].label)
  end
  return stack[1]
end
 
 
-- ***** ***** ***** ***** ***** parsing the tilemap xml file

local function getInfo(node)
	local info = {}

	info['tileW'] = tonumber(node.xarg['tilewidth'])
	info['tileH'] = tonumber(node.xarg['tileheight'])

	info['cols'] = tonumber(node.xarg['width'])
	info['rows'] = tonumber(node.xarg['height'])

	return info
end

local function getObjects(node)
	local objects = {}
	local id = 1
	--print "Loading objects"
    for k, sub in ipairs(node) do
        if (sub.label == "objectgroup") then
			for l, lsub in ipairs(sub) do

				objects[id] = {}
				objects[id]['name'] = lsub.xarg.name or ""
				objects[id]['type'] = lsub.xarg.type or ""
				objects[id]['x'] = tonumber(lsub.xarg.x)
				objects[id]['y'] = tonumber(lsub.xarg.y)
				objects[id]['w'] = tonumber(lsub.xarg.width)
				objects[id]['h'] = tonumber(lsub.xarg.height)
				objects[id]['gid'] = tonumber(lsub.xarg.gid)
				objects[id]['props'] = {}
	
				--printf("Loaded object %s - %s\n", objects[id]['name'], objects[id]['type']);

				if lsub[1] and lsub[1].label == "properties" then
					for m, msub in ipairs(lsub[1]) do
						--printf("+Have %d = %s <%s = %s>\n", m, msub.label, msub.xarg.name, msub.xarg.value)
						objects[id]['props'][msub.xarg.name] = msub.xarg.value
					end
				end

				id = id + 1
			end

        end
    end
    return objects
end

local function getBackgrounds(node)
	local backgrounds = {}
	local id = 1
	--print "Loading backgrounds"
    for k, sub in ipairs(node) do
        if (sub.label == "imagelayer") then
			local filename = sub[1].xarg.source

			backgrounds[id] = {}
			backgrounds[id]['file'] = filename
			backgrounds[id]['props'] = {}

			for l, lsub in ipairs(sub) do
				--printf("Have %d = %s\n", lsub.xarg.id, lsub.label)
				if (lsub.label == "properties") then
					for m, msub in ipairs(lsub) do
						--printf("+Have %d = %s <%s = %s>\n", m, msub.label, msub.xarg.name, msub.xarg.value)
						backgrounds[id]['props'][msub.xarg.name] = msub.xarg.value
					end
				end
			end

			id = id + 1
        end
    end
    return backgrounds
end

local function getTilesets(node)
	local tilesets = {}
	local i = 1
    for k, sub in ipairs(node) do
        if (sub.label == "tileset") then
			local ts = {}

			ts['first_gid'] = tonumber(sub.xarg.firstgid)
			ts['tile_w'] = tonumber(sub.xarg.tilewidth)
			ts['tile_h'] = tonumber(sub.xarg.tileheight)
			ts['file'] = sub[1].xarg.source
			ts['props'] = {}
			ts['anim'] = {}

			for l, lsub in ipairs(sub) do
				if (lsub.label == "image") then
					--printf("Have image %s\n", lsub.xarg.source)
				end
				if (lsub.label == "tile") then
					--printf("Have %d = %s\n", lsub.xarg.id, lsub.label)
					for n, nsub in ipairs(lsub) do
						if (nsub.label == "animation") then
							local tileid = lsub.xarg.id + ts['first_gid'] - 1
							-- for each frame
							ts.anim[tileid] = {}
							for m, msub in ipairs(nsub) do

								local mtileid = msub.xarg.tileid --- + ts['first_gid'] - 1
								local duration = tonumber(msub.xarg.duration) / 1000
								--printf("+Have frame %d = <tile = %d> <duration=%f>\n", m, mtileid, duration)

								ts.anim[tileid][m] = {}
								ts.anim[tileid][m]["gid"] = mtileid
								ts.anim[tileid][m]["delay"] = duration
							end

						end
						if (nsub.label == "properties") then
							for m, msub in ipairs(nsub) do
								--printf("+Have %d = %s <%s = %s>\n", m, msub.label, msub.xarg.name, msub.xarg.value)
								local tileid = lsub.xarg.id + ts['first_gid'] - 1
								if ts.props[tileid] == nil then
									ts.props[tileid] = {}
								end
								ts.props[tileid][msub.xarg.name] = msub.xarg.value
							end
						end
					end

				end
			end

			tilesets[i] = ts
			i = i + 1
        end
    end
    return tilesets
end

local function getLayers(node)
    local layers = {}
    for k, sub in ipairs(node) do
        if (sub.label == "layer") then --  and sub.xarg.name == layer_name
            local layer = {}
            table.insert(layers,layer)
			layer.name = sub.xarg.name
			layer.visible = tonumber(sub.xarg.visible)
			layer.width = tonumber(sub.xarg.width)
			layer.height = tonumber(sub.xarg.height)
			--~ print("layername",layer.name)

			if (sub[1].label == "data") then
				if (sub[1].xarg.encoding == "csv") then
					local csv = sub[1][1]
					local line, val
					local i, j = 0, -1 --should skip empty lines instead
					for line in string.gmatch(csv, "[^\n]+") do
						layer[j] = {}
						i = 0
						for val in string.gmatch(line, "%d+") do
							layer[j][i] = tonumber(val)
							i = i + 1
						end
						j = j + 1
						if j >= layer.height then -- should skip empty lines instead
							break
						end
					end
				else
					local i, j = 0, 0
					for l, child in ipairs(sub[1]) do
						if (i == 0) then
							layer[j] = {}
						end
						layer[j][i] = tonumber(child.xarg.gid)
						i = i + 1
						if i >= layer.width then
							i = 0
							j = j + 1
						end
					end
				end
			end
        end
    end
    return layers
end
 
function TiledMap_Parse(filename)
    local xml = LoadXML(love.filesystem.read(filename))
    local info = getInfo(xml[2])
    local tiles = getTilesets(xml[2])
    local layers = getLayers(xml[2])
	local backgrounds = getBackgrounds(xml[2])
	local objects = getObjects(xml[2])
    return info, tiles, layers, backgrounds, objects
end
