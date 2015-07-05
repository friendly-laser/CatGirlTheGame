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

local function getBackgrounds(node)
	local backgrounds = {}
	local id = 1
	print "Loading backgrounds"
    for k, sub in ipairs(node) do
        if (sub.label == "imagelayer") then
			local filename = sub[1].xarg.source

			backgrounds[id] = {}
			backgrounds[id]['file'] = filename
			backgrounds[id]['props'] = {}

			for l, lsub in ipairs(sub) do
				if (lsub.label == "image") then
					printf("Have image %s\n", lsub.xarg.source)
				end
				if (lsub.label == "properties") then
					--printf("Have %d = %s\n", lsub.xarg.id, lsub.label)
					for m, msub in ipairs(lsub) do
						printf("+Have %d = %s <%s = %s>\n", m, msub.label, msub.xarg.name, msub.xarg.value)
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
    local tiles = {}
	local props = {}
    for k, sub in ipairs(node) do
        if (sub.label == "tileset") then
            tiles[tonumber(sub.xarg.firstgid)] = sub[1].xarg.source

			for l, lsub in ipairs(sub) do
				if (lsub.label == "image") then
					--printf("Have image %s\n", lsub.xarg.source)
				end
				if (lsub.label == "tile") then
					--printf("Have %d = %s\n", lsub.xarg.id, lsub.label)
					for m, msub in ipairs(lsub[1]) do
						--printf("+Have %d = %s <%s = %s>\n", m, msub.label, msub.xarg.name, msub.xarg.value)
						if props[lsub.xarg.id] == nil then
							props[lsub.xarg.id] = {}
						end
						props[lsub.xarg.id][msub.xarg.name] = msub.xarg.value
					end
				end
			end
        end
    end
	tilesets.props = props
	tilesets.tiles = tiles
    return tilesets
end

local function getLayers(node)
    local layers = {}
	layers.width = 0
	layers.height = 0
    for k, sub in ipairs(node) do
        if (sub.label == "layer") then --  and sub.xarg.name == layer_name
			layers.width  = math.max(layers.width ,tonumber(sub.xarg.width ) or 0)
			layers.height = math.max(layers.height,tonumber(sub.xarg.height) or 0)
            local layer = {}
            table.insert(layers,layer)
			layer.name = sub.xarg.name
			--~ print("layername",layer.name)
            width = tonumber(sub.xarg.width)
            i = 0
            j = 0
            for l, child in ipairs(sub[1]) do
                if (j == 0) then
                    layer[i] = {}
                end
                layer[i][j] = tonumber(child.xarg.gid)
                j = j + 1
                if j >= width then
                    j = 0
                    i = i + 1
                end
            end
        end
    end
    return layers
end
 
function TiledMap_Parse(filename)
    local xml = LoadXML(love.filesystem.read(filename))
    local tiles = getTilesets(xml[2])
    local layers = getLayers(xml[2])
	local backgrounds = getBackgrounds(xml[2])
    return tiles, layers, backgrounds
end
