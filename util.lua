function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function trif(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end

function printf(s, ...)
	return io.write(s:format(...))
end

function dumps(o)
	if o == nil then
		printf("NULL");
	end
	if type(o) == "table" then
		printf("{ ");
		local k,v
		for k,v in pairs(o) do
			dumps(k)
			printf(": ")
			dumps(v)
			printf(", ")
		end
		printf("} ");
	end
	if type(o) == "string" then
		printf("\"%s\"", o)
	end
	if type(o) == "number" then
		printf("%d", o)
	end
end

function ini1dump(table)
	local ret = ""
	local k,v
	for k,v in pairs(table) do
		ret = ret .. k .. " = " .. v .. "\n"
	end
	return ret
end

function make_matrix(w, h)
	local grid = {}
	for j = 1, h do
		grid[j] = {}
		for i = 1, w do
			grid[j][i] = 0 -- Fill the values here
		end
	end
	return grid
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end
function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end
