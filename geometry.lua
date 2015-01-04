local geometry = {}

function geometry.normalize_angle(a)
	-- Normalize angle so that -π < a <= π.
	while a <= -math.pi do
		a = a + math.pi * 2
	end
	while a > math.pi do
		a = a - math.pi * 2
	end
	return a
end

function geometry.shortest_angle_to_angle(from_angle, to_angle)
	-- Shortest angle to turn by to get to the destination.
	from_angle = geometry.normalize_angle(from_angle)
	to_angle = geometry.normalize_angle(to_angle)
	return geometry.normalize_angle(to_angle - from_angle)
end

function geometry.segment_intersection(ax, ay, bx, by, cx, cy, dx, dy)
	-- Point where lines AB and CD intersect.
	-- http://www.faqs.org/faqs/graphics/algorithms-faq/ (1.03)
    local r_num = (ay - cy) * (dx - cx) - (ax - cx) * (dy - cy)
    local r_den = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx)
    local s_num = (ay - cy) * (bx - ax) - (ax - cx) * (by - ay)
    local s_den = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx)
    if r_den == 0 or s_den == 0 then  -- Parallel?
    	return nil
    end
    local r = r_num / r_den
    local s = s_num / s_den
    if r < 0 or r >= 1 or s < 0 or s >= 1 then
    	return nil
    end
    local px = ax + r * (bx - ax)
    local py = ay + r * (by - ay)
    return px, py
end

function geometry.distance_to_accelerate(initial_speed, target_speed, acceleration)
	-- How much space it'll take to change speed
	-- v^2 = u^2 + 2as
	return (target_speed ^ 2 - initial_speed ^ 2) / (-2 * acceleration)
end

-- Test normalize_angle
assert(geometry.normalize_angle(0) == 0)
assert(geometry.normalize_angle(math.pi) == math.pi)
assert(geometry.normalize_angle(-math.pi) == math.pi)
assert(geometry.normalize_angle(math.pi * 8) == 0)

-- Test shortest_angle_to_angle
assert(geometry.shortest_angle_to_angle(0, 0) == 0)
assert(geometry.shortest_angle_to_angle(0, -1) == -1)
assert(geometry.shortest_angle_to_angle(0, 1) == 1)
assert(geometry.shortest_angle_to_angle(0, 2 * math.pi + 1) == 1)
assert(geometry.shortest_angle_to_angle(0, 2 * math.pi - 1) == -1)
assert(geometry.shortest_angle_to_angle(math.pi - 0.5, math.pi + 0.5) == 1)
assert(geometry.shortest_angle_to_angle(math.pi + 0.5, math.pi - 0.5) == -1)

-- Test distance_to_accelerate
-- TODO:

-- Test segment_intersection
local x, y = geometry.segment_intersection(-1, 0, 1, 0, 0, -1, 0, 1)
assert(x == 0 and y == 0)
x, y = geometry.segment_intersection(-2, -1, 0, 1, -1, 0, 1, 0)
assert(x == -1 and y == 0)
x, y = geometry.segment_intersection(-1, 0, 1, 0, -1, 1, 1, 1)
assert(x == nil and y == nil)
-- x, y = geometry.segment_intersection(10, 590, 790, 590, 400, 300, 220, 1242)
-- assert(false)


return geometry
