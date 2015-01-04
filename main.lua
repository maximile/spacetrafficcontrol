require("strict")
local geometry = require("geometry")
local spookyghost = require("spookyghost")
local ship = require("ship")
local airspace = require("airspace")

time = 0.0
final_time = nil
player_ship = ship.Ship.new()
spooky_ghosts = nil

arrow_image = nil
marker_image = nil
spooky_ghost_image = nil
marker_font = nil
intro_font = nil
intro_font_small = nil

space = nil

function love.load()
    time = 0.0
    final_time = nil
    player_ship = ship.Ship.new()
    
    spooky_ghosts = {
        spookyghost.new(-2000, 6200, 255, 255, 180),
        spookyghost.new(59000, 6800, 255, 180, 180),
        spookyghost.new(64000, 9900, 180, 255, 180),
        spookyghost.new(-190000, -70000, 180, 255, 255)
    }
    space = airspace.Airspace.new()
    space.max_speed = 500.0
    space:set_points(200, 200, -200, 200, -200, 600)
    
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
        player_ship.turn_left = true
    end
    if key == "right" then
        player_ship.turn_right = true
    end
    if key == "up" then
        player_ship.accelerate = true
    end
    if key == "down" then
        player_ship.turn_back = true
    end
end

function love.keyreleased(key)
    if key == "left" then
        player_ship.turn_left = false
    end
    if key == "right" then
        player_ship.turn_right = false
    end
    if key == "up" then
        player_ship.accelerate = false
    end
    if key == "down" then
        player_ship.turn_back = false
    end
end

function world_to_screen(x, y)
    x = x + (-player_ship.pos_x + love.graphics.getWidth() / 2)
    y = y + (-player_ship.pos_y + love.graphics.getHeight() / 2)
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
    
    player_ship:update(dt)
    
    for _, ghost in ipairs(spooky_ghosts) do
        local dist = math.sqrt((player_ship.pos_x - ghost.pos_x) ^ 2 + 
                               (player_ship.pos_y - ghost.pos_y) ^ 2)
        if dist < 150 then
            ghost.harmed = true
            ghost.health = ghost.health - dt / 2
        else
            ghost.harmed = false
        end
    end
end

function draw_grid(min_x, max_x, min_y, max_y, dim)
    local start_x = math.floor(min_x / dim) * dim
    local end_x = math.floor(max_x / dim) * dim
    for x = start_x, end_x, dim do
        love.graphics.line(x, min_y, x, max_y)
    end
    local start_y = math.floor(min_y / dim) * dim
    local end_y = math.floor(max_y / dim) * dim
    for y = start_y, end_y, dim do
        love.graphics.line(min_x, y, max_x, y)
    end
end

function draw_marker(x, y)
    -- Need four lines for the screen borders
    local margin = 40
    local margin_bottom = 80
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local edges = {}
    edges["top"] = {ax=margin, ay=margin,
                      bx=screen_width - margin, by=margin}
    edges["bottom"] = {ax=margin, ay=screen_height - margin_bottom,
                         bx=screen_width - margin, by=screen_height - margin_bottom}
    edges["left"] = {ax=margin, ay=margin,
                       bx=margin, by=screen_height - margin_bottom}
    edges["right"] = {ax=screen_width - margin, ay=margin,
                        bx=screen_width - margin, by=screen_height - margin_bottom}
    
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
        local angle = math.atan2(center_y - target_y, center_x - target_x) - math.pi
        local width, height = marker_image:getDimensions()
        love.graphics.draw(marker_image, intersect_x, intersect_y, angle, 1.0, 1.0, width/2, height/2)
        
        local distance = math.sqrt((target_x - center_x) ^ 2 + (target_y - center_y) ^ 2)
        local distance_str = nil
        if distance < 10000 then
            distance_str = string.format("%0.1fKM", distance / 1000)
        else
            distance_str = string.format("%0.0fKM", distance / 1000)
        end
        
        -- Find which color to draw with - red if we're going to miss it,
        -- yellow if we need to slow down soon.
        local speed = player_ship:get_speed()
        local required_dist = geometry.distance_to_accelerate(speed, 0,
                                                    player_ship.acceleration)
        local time_to_decision_dist = (distance - required_dist) / speed
        local warning_time = 10.0
        
        if required_dist > distance then
            love.graphics.setColor(255, 0, 0)
        elseif time_to_decision_dist < warning_time then
            love.graphics.setColor(255, 127, 0)
            love.graphics.setLineWidth(2.0)
            local progress_range = 70
            local total_start_x = intersect_x - progress_range / 2
            local total_end_x = intersect_x + progress_range / 2
            local total_y = intersect_y + 36
            local progress = time_to_decision_dist / warning_time
            local progress_x = total_start_x + progress_range * progress
            love.graphics.line(total_start_x, total_y, total_end_x, total_y)
            love.graphics.line(progress_x, total_y, progress_x, total_y + 5)
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
    love.graphics.push()
    love.graphics.translate(-player_ship.pos_x + love.graphics.getWidth() / 2, -player_ship.pos_y + love.graphics.getHeight() / 2)
    
    love.graphics.setColor(255, 180, 180, 127)
    space:draw()
    
    love.graphics.setLineWidth(160)
    love.graphics.setLineJoin("bevel")
    love.graphics.setColor(20, 60, 40)
    -- love.graphics.line(0, 0, 600, 600, 1200, 600)
    
    -- Draw grid
    love.graphics.setLineWidth(1)
    love.graphics.setColor(120, 120, 120)
    local min_x = player_ship.pos_x - love.graphics.getWidth() / 2
    local max_x = player_ship.pos_x + love.graphics.getWidth() / 2
    local min_y = player_ship.pos_y - love.graphics.getHeight() / 2
    local max_y = player_ship.pos_y + love.graphics.getHeight() / 2
    draw_grid(min_x, max_x, min_y, max_y, 200)
    
    -- Draw course marker
    local course_x = math.cos(player_ship:get_course()) * 1000 + player_ship.pos_x
    local course_y = math.sin(player_ship:get_course()) * 1000 + player_ship.pos_y
    love.graphics.line(player_ship.pos_x, player_ship.pos_y, course_x, course_y)
    
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

    if space:contains(player_ship.pos_x, player_ship.pos_y) then
        love.graphics.setColor(255, 0, 0)
    else
        love.graphics.setColor(255, 255, 255)
    end
    player_ship:draw()
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
        local time_str = string.format("Time taken: %0.1fs", final_time)
        love.graphics.printf(time_str, 0, screen_height * (5 / 7), screen_width, "center")
    end

    
    -- Screen space stuff
    for _, ghost in ipairs(spooky_ghosts) do
        if ghost.health > 0.0 then
            love.graphics.setColor(ghost.col_r, ghost.col_g, ghost.col_b)
            draw_marker(ghost.pos_x, ghost.pos_y)
        end
    end
    
    love.graphics.setColor(255, 255, 255)
    local speed_str = string.format("Speed: %0.1fm/s", player_ship:get_speed())
    love.graphics.print(speed_str, 40, screen_height - 40)
    local heading = math.deg(geometry.normalize_angle(player_ship.angle - math.pi / 2)) + 180
    local heading_str = string.format("Heading: %03i°", heading)
    love.graphics.print(heading_str, 280, screen_height - 40)
    local course = math.deg(math.atan2(player_ship.vel_y, player_ship.vel_x) + math.pi / 2)
    if course < 0 then
        course = course + 360
    end
    local course_str = string.format("Course: %03i°", course)
    love.graphics.print(course_str, 500, screen_height - 40)


    
    -- love.graphics.setColor(255, 200, 200)
    -- draw_marker(50000, -23000)
    -- love.graphics.setColor(180, 180, 255)
    -- draw_marker(-5000, -3000)
    -- love.graphics.setColor(180, 255, 180)
    -- draw_marker(-500000, -23000)

end
