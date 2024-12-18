function readOnly(t)
	local proxy = {}
	local mt = {
		__index = t,
		__newindex = function(t, k, v)
			error("attempt to update a read-only value", 2)
		end,
	}
	setmetatable(proxy, mt)
	return proxy
end

--- Returns average number of a table
---@param t Table
---@return average number
function math.average(t)
	local sum = 0
	for _, v in pairs(t) do -- Get the sum of all numbers in t
		sum = sum + v
	end
	return sum / #t
end

function math.randomizer(index, range)
	math.randomseed(os.clock() + index)
	math.random()
	return math.random(-range, range)
end

--- Log messages
--- @param message string
function log(message)
	ac.log("[RARE] " .. message)
end

--- Log error messages
--- @param message string
function error(message)
	ac.error("[RARE] " .. message)
end

function table.containsValue(tbl, x)
	local found = false
	for _, v in pairs(tbl) do
		if tonumber(v) == tonumber(x) then
			found = true
		end
	end
	return found
end
