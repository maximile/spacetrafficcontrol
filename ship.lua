geometry = require("geometry")

local ship = {}
ship.Ship = {}
ship.Ship.__index = ship.Ship

function ship.Ship.new()
	local self = setmetatable({}, ship.Ship)
	
	-- Physical properties
	self.vel_x = 0  -- m/s
	self.vel_y = 0  -- m/s
	self.pos_x = 0  -- m
	self.pos_y = 0  -- m
	self.angle = 0  -- rad
	
	-- Performance capability
	self.acceleration = 65  -- m/s/s
	self.turn_rate = 2.4   -- rad/s
	
	-- Inputs
	self.turn_left = false
	self.turn_right = false
	self.accelerate = false
	self.turn_back = false
	
	-- Graphical stuff
	self.image = love.graphics.newImage("ship.png")
	local particle_image = love.graphics.newImage("exhaust.png")
	
	-- (One particle emitter for each engine)
	self.particle_emitter_left = love.graphics.newParticleSystem(particle_image, 1000)
	self.particle_emitter_left:setParticleLifetime(0.2, 1.0)
	self.particle_emitter_left:setSizes(0.2, 1.0)
	self.particle_emitter_right = love.graphics.newParticleSystem(particle_image, 1000)
	self.particle_emitter_right:setParticleLifetime(0.2, 1.0)
	self.particle_emitter_right:setSizes(0.2, 1.0)
	self.particle_emitter_right:setSpread(0.2)
	self.particle_emitter_left:setSpread(0.2)
	self.particle_emitter_left:setAreaSpread("uniform", 2, 2)
	self.particle_emitter_right:setAreaSpread("uniform", 2, 2)
	self.particle_emitter_left:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	self.particle_emitter_right:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	
	return self
end

function ship.Ship.get_speed(self)
	return math.sqrt(self.vel_x ^ 2 + self.vel_y ^ 2)
end

function ship.Ship.get_course(self)
	-- Direction the ship is travelling (not which way it's pointing)
	return math.atan2(self.vel_y, self.vel_x)
end

function ship.Ship.draw(self)
    love.graphics.draw(self.particle_emitter_left)
    love.graphics.draw(self.particle_emitter_right)
    local width, height = player_ship.image:getDimensions()
    love.graphics.draw(self.image, self.pos_x, self.pos_y,
    				   self.angle + math.pi / 2, 1.0, 1.0, width/2, height/2)
end

function ship.Ship.update(self, dt)
	-- Handle inputs. Forwards:
	if self.accelerate then
		local speed_change = self.acceleration * dt
        self.vel_x = self.vel_x + math.cos(self.angle) * speed_change
        self.vel_y = self.vel_y + math.sin(self.angle) * speed_change
        self.particle_emitter_left:setEmissionRate(100.0)
        self.particle_emitter_right:setEmissionRate(100.0)
	else
        self.particle_emitter_left:setEmissionRate(0.0)
        self.particle_emitter_right:setEmissionRate(0.0)
    end
	
	-- Back, left or right (all involve turning)
    if self.turn_back then
        local travelling_angle = math.atan2(self.vel_y, self.vel_x)
        local target_angle = travelling_angle + math.pi
        local ideal_turn = geometry.shortest_angle_to_angle(self.angle, target_angle)
        if ideal_turn > (self.turn_rate * dt) then
            ideal_turn = self.turn_rate * dt
        elseif ideal_turn < (-self.turn_rate * dt) then
            ideal_turn = -self.turn_rate * dt
        end
        self.angle = self.angle + ideal_turn
    else
        if self.turn_right then
            self.angle = self.angle + self.turn_rate * dt
        end
        if self.turn_left then
            self.angle = self.angle - self.turn_rate * dt
        end
    end
    
    -- Update position from velocity
    self.pos_x = self.pos_x + (self.vel_x * dt)
    self.pos_y = self.pos_y + (self.vel_y * dt)
    
    -- Update particle thing
    self.particle_emitter_left:setPosition(self:local_to_world(-30, -45))
    self.particle_emitter_right:setPosition(self:local_to_world(-30, 45))
    -- self.particle_emitter_right:setPosition(self.pos_x - math.cos(self.angle + math.pi / 2) * 45,
    -- 									   self.pos_y - math.sin(self.angle + math.pi / 2) * 45)
    local emission_vel_x = self.vel_x + math.cos(self.angle + math.pi) * 500
    local emission_vel_y = self.vel_y + math.sin(self.angle + math.pi) * 500
    local emission_angle = math.atan2(emission_vel_y, emission_vel_x)
    local emission_speed = math.sqrt(emission_vel_x ^ 2 + emission_vel_y ^ 2)
    self.particle_emitter_left:setDirection(emission_angle)
	self.particle_emitter_left:setSpeed(emission_speed)
    self.particle_emitter_left:update(dt)
    self.particle_emitter_right:setDirection(emission_angle)
	self.particle_emitter_right:setSpeed(emission_speed)
    self.particle_emitter_right:update(dt)
end

function ship.Ship.local_to_world(self, x, y)
	-- Convert point to wold space. Rotate:
	local new_x = x * math.cos(self.angle) - y * math.sin(self.angle)
	local new_y = x * math.sin(self.angle) + y * math.cos(self.angle)
	return new_x + self.pos_x, new_y + self.pos_y
end
	
return ship
