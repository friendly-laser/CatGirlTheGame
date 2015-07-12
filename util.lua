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
		local coma = " "
		for k,v in pairs(o) do
			printf("%s", coma)
			dumps(k)
			printf(": ")
			dumps(v)
			coma = ", "
		end
		printf("} ");
	end
	if type(o) == "boolean" then
		if o == true then
			printf("true");
		else
			printf("false");
		end
	end
	if type(o) == "string" then
		printf("\"%s\"", o)
	end
	if type(o) == "number" then
		--meh, this could be %f
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

function make_matrix(w, h, val)
	local grid = {}
	local j, i
	val = val or 0
	for j = 1, h do
		grid[j] = {}
		for i = 1, w do
			grid[j][i] = val
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

function math.abs(n)
	if n < 0 then
		return -n,-1
	else
		return n,1
	end
end
