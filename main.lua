local geometry = require("geometry")
local spookyghost = require("spookyghost")

function love.load()
    time = 0.0
    final_time = nil
    ship = {
        angle = 0.0,
        pos_x = 0.0,
        pos_y = 0.0,
        vel_x = 0.0,
        vel_y = 0.0,
        acceleration = 0.2,
        turn_rate = 4.0,
        turning_left = false,
        turning_right = false,
        turning_back = false,
        accelerating = false
    }
    spooky_ghosts = {
        spookyghost.new(-2000, 6200, 255, 255, 180),
        spookyghost.new(59000, 6800, 255, 180, 180),
        spookyghost.new(64000, 9900, 180, 255, 180),
        spookyghost.new(-190000, -70000, 180, 255, 255)
    }
    ship_image = love.graphics.newImage("ship.png")
    arrow_image = love.graphics.newImage("arrow.png")
    marker_image = love.graphics.newImage("marker.png")
    spooky_ghost_image = love.graphics.newImage("spooky.png")
    marker_font = love.graphics.newFont("fonts/ArchivoBlack-Regular.otf", 20)
    intro_font = love.graphics.newFont("fonts/AllerDisplay.ttf", 80)
    intro_font_small = love.graphics.newFont("fonts/AllerDisplay.ttf", 40)
    -- love.graphics.setNewFont(40)
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
    time = time + dt
    if dt > 1 / 30 then
        dt = 1 / 30
    end
    
    local alive_ghost_count = 0
    for _, ghost in ipairs(spooky_ghosts) do
        if ghost.health > 0.0 then
            alive_ghost_count = alive_ghost_count + 1
        end
    end
    if alive_ghost_count == 0 and final_time == nil then
        final_time = time
    end

    
    if ship.turning_back then
        travelling_angle = math.atan2(ship.vel_y, ship.vel_x)
        target_angle = travelling_angle + math.pi
        ideal_turn = geometry.shortest_angle_to_angle(ship.angle, target_angle)
        if ideal_turn > (ship.turn_rate * dt) then
            ideal_turn = ship.turn_rate * dt
        elseif ideal_turn < (-ship.turn_rate * dt) then
            ideal_turn = -ship.turn_rate * dt
        end
        ship.angle = ship.angle + ideal_turn
    else
        if ship.turning_right then
            ship.angle = ship.angle + ship.turn_rate * dt
        end
        if ship.turning_left then
            ship.angle = ship.angle - ship.turn_rate * dt
        end
    end
    
    if ship.accelerating then
        ship.vel_x = ship.vel_x + math.cos(ship.angle) * ship.acceleration
        ship.vel_y = ship.vel_y + math.sin(ship.angle) * ship.acceleration
    end
    ship.pos_x = ship.pos_x + ship.vel_x
    ship.pos_y = ship.pos_y + ship.vel_y
    
    for _, ghost in ipairs(spooky_ghosts) do
        local dist = math.sqrt((ship.pos_x - ghost.pos_x) ^ 2 + 
                               (ship.pos_y - ghost.pos_y) ^ 2)
        if dist < 150 then
            ghost.harmed = true
            ghost.health = ghost.health - dt / 2
        else
            ghost.harmed = false
        end
    end
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

function new_ghost(x, y, r, g, b)
    local ghost = {pos_x}
end

function draw_marker(x, y)
    -- Need four lines for the screen borders
    local margin = 40
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
    for edge, values in pairs(edges) do
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
        
        distance = math.sqrt((target_x - center_x) ^ 2 + (target_y - center_y) ^ 2)
        if distance < 10000 then
            distance_str = string.format("%0.1fKM", distance / 1000)
        else
            distance_str = string.format("%0.0fKM", distance / 1000)
        end
        
        -- Find which color to draw with - red if we're going to miss it,
        -- yellow if we need to slow down soon.
        local travelling_angle = math.atan2(ship.vel_y, ship.vel_x)
        local reverse_angle = travelling_angle + math.pi
        local angle_to_turn = geometry.shortest_angle_to_angle(ship.angle, reverse_angle)
        local time_to_turn = angle_to_turn / ship.turn_rate
        speed = math.sqrt(ship.vel_x ^ 2 + ship.vel_y ^ 2)
        required_dist = geometry.distance_to_accelerate(speed, 0, ship.acceleration)
        if required_dist > distance then
            love.graphics.setColor(255, 0, 0)
        end
        
        love.graphics.setFont(marker_font)
        love.graphics.printf(distance_str, intersect_x - 100, intersect_y + 10, 200, "center")
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
    -- love.graphics.line(0, 0, 600, 600, 1200, 600)

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
        
    local ghost_width, ghost_height = spooky_ghost_image:getDimensions()
    for _, ghost in ipairs(spooky_ghosts) do
        if ghost.harmed then
            love.graphics.setColor(255, 0, 0)
        else
            love.graphics.setColor(ghost.col_r, ghost.col_g, ghost.col_b)
        end
        
        if ghost.health > 0.0 then
            love.graphics.draw(spooky_ghost_image, ghost.pos_x, ghost.pos_y,
                               0.0, 1.0, 1.0, ghost_width / 2, ghost_height / 2)
        end
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(ship_image, ship.pos_x, ship.pos_y, ship.angle + math.pi / 2, 1.0, 1.0, width/2, height/2)
    love.graphics.pop()
    
    
    -- Draw text
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    
    if time < 6.0 then
        local opacity = 1.0
        if time > 5.0 then
            opacity = 6.0 - time
        end
        love.graphics.setColor(255, 255, 255, opacity * 255)
        love.graphics.setFont(intro_font)
        love.graphics.printf("Mission One", 0, screen_height / 7, screen_width, "center")
        love.graphics.setFont(intro_font_small)
        love.graphics.printf("Dismiss the Spooky Ghosts", 0, screen_height * (5 / 7), screen_width, "center")
    end
    
    -- Success text
    local alive_ghost_count = 0
    for _, ghost in ipairs(spooky_ghosts) do
        if ghost.health > 0.0 then
            alive_ghost_count = alive_ghost_count + 1
        end
    end
    if final_time ~= nil then
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(intro_font)
        love.graphics.printf("Mission Complete", 0, screen_height / 7, screen_width, "center")
        love.graphics.setFont(intro_font_small)
        time_str = string.format("Time taken: %0.1fs", final_time)
        love.graphics.printf(time_str, 0, screen_height * (5 / 7), screen_width, "center")
    end

    
    -- Screen space stuff
    for _, ghost in ipairs(spooky_ghosts) do
        if ghost.health > 0.0 then
            love.graphics.setColor(ghost.col_r, ghost.col_g, ghost.col_b)
            draw_marker(ghost.pos_x, ghost.pos_y)
        end
    end

    
    -- love.graphics.setColor(255, 200, 200)
    -- draw_marker(50000, -23000)
    -- love.graphics.setColor(180, 180, 255)
    -- draw_marker(-5000, -3000)
    -- love.graphics.setColor(180, 255, 180)
    -- draw_marker(-500000, -23000)

end
