inspect = require("inspect")
geometry = require("geometry")

local airspace = {}
airspace.Airspace = {}
airspace.Airspace.__index = airspace.Airspace

function airspace.Airspace.new(...)
	local self = setmetatable({}, airspace.Airspace)
	self._points = {}
	self.min_x = 0
	self.max_x = 0
	self.min_y = 0
	self.max_y = 0
	self.min_speed = 0
	self.max_speed = math.huge
	
	return self
end

function airspace.Airspace.set_points(self, ...)
	local points = {...}
	if #points % 2 ~= 0 then
		error("Even number of coords required")
	end
	self._points = points
	
	-- Update the cached bounding box
	local x, y
	local index = 1
	while true do
		x = points[index]
		y = points[index + 1]
		if x == nil then
			break
		end
		if x < self.min_x then
			self.min_x = x
		end
		if x > self.max_x then
			self.max_x = x
		end
		if y < self.min_y then
			self.min_y = y
		end
		if y > self.max_y then
			self.max_y = y
		end
		index = index + 2
	end
end

function airspace.Airspace.contains(self, x, y)
	-- Whether the point sits inside the polygon.
	
	-- If the point is outside the bounding box, we know it isn't contained.
	if x < self.min_x or x > self.max_x or y < self.min_y or y > self.max_y then
		return false
	end
	
	-- Test every edge for intersection with a line from the point to some
	-- point outside the polygon. If the number of intersections is odd, the
	-- point is inside. So first, get a point that we know is outside.
	local outside_x = self.max_x + 1
	local outside_y = self.max_y + 1
	
	-- Count how many times the line intersects one of our edges
	local intersection_count = 0
	local index = 1
	local points = self._points
	local prev_x = self._points[#points - 1]
	local prev_y = self._points[#points]
	while true do
		local next_x = points[index]
		local next_y = points[index + 1]
		if next_x == nil then
			break
		end
		if geometry.segment_intersection(x, y, outside_x, outside_y,
							 			prev_x, prev_y, next_x, next_y) then
			intersection_count = intersection_count + 1
		end
		prev_x, prev_y = next_x, next_y
		index = index + 2
	end
	
	-- Odd number of intersections? It's inside.
	if intersection_count % 2 == 1 then
		return true
	end
	return false
end

function airspace.Airspace.draw(self)
	love.graphics.polygon("fill", self._points)
	love.graphics.polygon("line", self._points)
end

function airspace.Airspace.violates(self, ship)
	if not self.contains(ship.pos_x, ship.pos_y) then
		return false
	end
	local speed = ship:get_speed()
	if speed > self.max_speed or speed < self.min_speed then
		return true
	end
	return false
end
	

-- Test functionality
test_space = airspace.Airspace.new()
test_space:set_points(-1, -1, 1, -1, 1, 1, -1, 1)
assert(test_space:contains(0, 0) == true)
assert(test_space:contains(2, 2) == false)


return airspace
