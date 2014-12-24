local geometry = require("geometry")

function love.load()
    ship = {
        angle = 0.0,
        pos_x = 0.0,
        pos_y = 0.0,
        vel_x = 0.0,
        vel_y = 0.0,
        turning_left = false,
        turning_right = false,
        turning_back = false,
        accelerating = false
    }
    ship_image = love.graphics.newImage("ship.png")
    arrow_image = love.graphics.newImage("arrow.png")
    marker_image = love.graphics.newImage("marker.png")
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

function world_to_screen(x, y)
    x = x + (-ship.pos_x + love.graphics.getWidth() / 2)
    y = y + (-ship.pos_y + love.graphics.getHeight() / 2)
    return x, y
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

function draw_marker(x, y)
    -- Need four lines for the screen borders
    local margin = 30
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local edges = {}
    edges["top"] = {ax=margin, ay=margin,
                      bx=screen_width - margin, by=margin}
    edges["bottom"] = {ax=margin, ay=screen_height - margin,
                         bx=screen_width - margin, by=screen_height - margin}
    edges["left"] = {ax=margin, ay=margin,
                       bx=margin, by=screen_height - margin}
    edges["right"] = {ax=screen_width - margin, ay=margin,
                        bx=screen_width - margin, by=screen_height - margin}
    
    -- Find where each line intersects the line from the player to the target
    local center_x = screen_width / 2
    local center_y = screen_height / 2
    local target_x, target_y = world_to_screen(x, y)
    local intersect_x, intersect_y
    for _, values in pairs(edges) do
        intersect_x, intersect_y = geometry.segment_intersection(
                        values.ax, values.ay, values.bx, values.by,
                        center_x, center_y, target_x, target_y)
        if intersect_x ~= nil then
            break
        end
    end
    
    -- Intersection? Draw a marker
    if intersect_x ~= nil then
        angle = math.atan2(center_y - target_y, center_x - target_x) - math.pi
        local width, height = marker_image:getDimensions()
        love.graphics.draw(marker_image, intersect_x, intersect_y, angle, 1.0, 1.0, width/2, height/2)
    end
    
    
    -- local width, height = marker_image:getDimensions()
    -- love.graphics.draw(marker_image, target_x, target_y, 0.0, 1.0, 1.0, width/2, height/2)
    
    -- width, height = arrow_image:getDimensions()
    -- angle = math.atan2(player_y - target_y, player_x - target_x)
    -- angle = angle - math.pi
    -- distance = math.sqrt(math.pow(target_x - player_x, 2) + math.pow(target_y - player_y, 2))
    -- love.graphics.draw(arrow_image, marker_x, marker_y, angle, 1.0, 1.0, width/2, height/2)
    -- love.graphics.print(string.format("%0.1fKM", distance / 1000), marker_x + 20, marker_y)
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
    --  love.graphics.line(val, -10000, val, 10000)
    -- end
    -- -- love.graphics.setLineWidth(ship.vel_y)
    -- for val = -10000, 10000, 200 do
    --  love.graphics.line(-10000, val, 10000, val)
    -- end
    
    
    -- draw_marker(0, 0)
    
    -- draw_marker(ship.pos_x, ship.pos_y, 50000, -23000, ship.pos_x + 200, ship.pos_y + 200)
    -- draw_marker(ship.pos_x, ship.pos_y, -200000, 170000, ship.pos_x - 200, ship.pos_y + 200)
    -- draw_marker(ship.pos_x, ship.pos_y, -2000000, 1700000, ship.pos_x - 200, ship.pos_y - 200)
    
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(ship_image, ship.pos_x, ship.pos_y, ship.angle + math.pi / 2, 1.0, 1.0, width/2, height/2)
    love.graphics.pop()
    

    
    -- Screen space stuff
    love.graphics.setColor(255, 200, 200)
    draw_marker(50000, -23000)
    love.graphics.setColor(180, 180, 255)
    draw_marker(-5000, -3000)
    love.graphics.setColor(180, 255, 180)
    draw_marker(-500000, -23000)

end
