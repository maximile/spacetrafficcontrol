local geometry = require("geometry")

function love.load()
	ship = {
		angle = 0.0,
		pos_x = 400.0,
		pos_y = 300.0,
		vel_x = 0.0,
		vel_y = 0.0,
		turning_left = false,
		turning_right = false,
		turning_back = false,
		accelerating = false
	}
	ship_image = love.graphics.newImage("ship.png")
	marker_image = love.graphics.newImage("spooky.png")
	arrow_image = love.graphics.newImage("arrow.png")
	love.graphics.setNewFont(40)
end

function love.keypressed(key)
	if key == "left" then
		ship.turning_left = true
	end
	if key == "right" then
		ship.turning_right = true
	end
	if key == "up" then
		ship.accelerating = true
	end
	if key == "down" then
		ship.turning_back = true
	end
end

function love.keyreleased(key)
	if key == "left" then
		ship.turning_left = false
	end
	if key == "right" then
		ship.turning_right = false
	end
	if key == "up" then
		ship.accelerating = false
	end
	if key == "down" then
		ship.turning_back = false
	end
end

function love.update(dt)
	if dt > 1 / 30 then
		dt = 1 / 30
	end
	
	if ship.turning_back then
		travelling_angle = math.atan2(ship.vel_y, ship.vel_x)
		target_angle = travelling_angle + math.pi
		ideal_turn = geometry.shortest_angle_to_angle(ship.angle, target_angle)
		if ideal_turn > (4.0 * dt) then
			ideal_turn = 4.0 * dt
		elseif ideal_turn < (-4.0 * dt) then
			ideal_turn = -4.0 * dt
		end
		ship.angle = ship.angle + ideal_turn
	else
		if ship.turning_right then
			ship.angle = ship.angle + 4.0 * dt
		end
		if ship.turning_left then
			ship.angle = ship.angle - 4.0 * dt
		end
	end
	
	if ship.accelerating then
		ship.vel_x = ship.vel_x + math.cos(ship.angle) * 0.2
		ship.vel_y = ship.vel_y + math.sin(ship.angle) * 0.2
	end
	ship.pos_x = ship.pos_x + ship.vel_x
	ship.pos_y = ship.pos_y + ship.vel_y
end

function draw_grid(min_x, max_x, min_y, max_y, dim)
	start_x = math.floor(min_x / dim) * dim
	end_x = math.floor(max_x / dim) * dim
	for x = start_x, end_x, dim do
		love.graphics.line(x, min_y, x, max_y)
	end
	start_y = math.floor(min_y / dim) * dim
	end_y = math.floor(max_y / dim) * dim
	for y = start_y, end_y, dim do
		love.graphics.line(min_x, y, max_x, y)
	end
end

function draw_marker(player_x, player_y, target_x, target_y, marker_x, marker_y)
	local width, height = marker_image:getDimensions()
	love.graphics.draw(marker_image, target_x, target_y, 0.0, 1.0, 1.0, width/2, height/2)
	
	width, height = arrow_image:getDimensions()
	angle = math.atan2(player_y - target_y, player_x - target_x)
	angle = angle - math.pi
	distance = math.sqrt(math.pow(target_x - player_x, 2) + math.pow(target_y - player_y, 2))
	love.graphics.draw(arrow_image, marker_x, marker_y, angle, 1.0, 1.0, width/2, height/2)
	love.graphics.print(string.format("%0.1fKM", distance / 1000), marker_x + 20, marker_y)
end

function love.draw()
	width, height = ship_image:getDimensions()
	love.graphics.push()
	love.graphics.translate(-ship.pos_x + love.graphics.getWidth() / 2, -ship.pos_y + love.graphics.getHeight() / 2)
	
	love.graphics.setLineWidth(160)
	love.graphics.setLineJoin("bevel")
	love.graphics.setColor(20, 60, 40)
	love.graphics.line(0, 0, 600, 600, 1200, 600)

	-- Draw grid
	love.graphics.setLineWidth(1)
	love.graphics.setColor(120, 120, 120)
	min_x = ship.pos_x - love.graphics.getWidth() / 2
	max_x = ship.pos_x + love.graphics.getWidth() / 2
	min_y = ship.pos_y - love.graphics.getHeight() / 2
	max_y = ship.pos_y + love.graphics.getHeight() / 2
	draw_grid(min_x, max_x, min_y, max_y, 200)
	
	-- -- grid_intensity_x = 
	-- for val = math.floor(-ship.pos_x / 200) * 200 - 1000, math.floor(-ship.pos_x / 200) * 200 + 1000, 200 do
	-- 	love.graphics.line(val, -10000, val, 10000)
	-- end
	-- -- love.graphics.setLineWidth(ship.vel_y)
	-- for val = -10000, 10000, 200 do
	-- 	love.graphics.line(-10000, val, 10000, val)
	-- end
	
	love.graphics.setColor(255, 255, 255)
	
	draw_marker(ship.pos_x, ship.pos_y, 50000, -23000, ship.pos_x + 200, ship.pos_y + 200)
	draw_marker(ship.pos_x, ship.pos_y, -200000, 170000, ship.pos_x - 200, ship.pos_y + 200)
	draw_marker(ship.pos_x, ship.pos_y, -2000000, 1700000, ship.pos_x - 200, ship.pos_y - 200)
	
	love.graphics.draw(ship_image, ship.pos_x, ship.pos_y, ship.angle + math.pi / 2, 1.0, 1.0, width/2, height/2)
	love.graphics.pop()
end
