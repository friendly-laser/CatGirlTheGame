function trif(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end

function printf(s, ...)
	return io.write(s:format(...))
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