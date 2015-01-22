geometry = require("geometry")
json = require("json")

local ship = {}
ship.Ship = {}
ship.Ship.__index = ship.Ship

function ship.Ship.new(config_name)
	local self = setmetatable({}, ship.Ship)
	
	-- Load details from config
	local json_data = love.filesystem.read(config_name)
	self.config = json:decode(json_data)
	
	-- Physical properties
	self.vel_x = 0  -- m/s
	self.vel_y = 0  -- m/s
	self.pos_x = 0  -- m
	self.pos_y = 0  -- m
	self.angle = 0  -- rad
		
	-- Inputs
	self.turn_left = false
	self.turn_right = false
	self.accelerate = 0.0
	self.turn_back = false
	
	-- Graphical stuff
	self.image = love.graphics.newImage("ship.png")
	local particle_image = love.graphics.newImage("exhaust.png")
	
	-- Create particle systems for any defined in config
	self.engine_particle_systems = {}
    for engine_name, data in pairs(self.config.engines) do
    	local particle_image = love.graphics.newImage(data.particle_image)
    	local particle_system = love.graphics.newParticleSystem(particle_image)
    	self.engine_particle_systems[engine_name] = particle_system
    	particle_system:setParticleLifetime(unpack(data.particle_lifetime))
    	particle_system:setSizes(unpack(data.particle_size))
    	particle_system:setSpread(data.particle_spread)
    	particle_system:setAreaSpread(unpack(data.particle_area_spread))
    	particle_system:setColors(unpack(data.particle_colors))
    end
	
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
	for _, particle_system in pairs(self.engine_particle_systems) do
		love.graphics.draw(particle_system)
	end
    local width, height = player_ship.image:getDimensions()
    love.graphics.draw(self.image, self.pos_x, self.pos_y,
    				   self.angle + math.pi / 2, 1.0, 1.0, width/2, height/2)
end

function ship.Ship.get_acceleration(self)
	return self.config.acceleration
end

function ship.Ship.update(self, dt)
	-- Handle inputs. Forwards:
	if self.accelerate then
		local speed_change = self.config.acceleration * dt * self.accelerate
        self.vel_x = self.vel_x + math.cos(self.angle) * speed_change
        self.vel_y = self.vel_y + math.sin(self.angle) * speed_change
        
        for engine_name, particle_system in pairs(self.engine_particle_systems) do
        	local emission_rate = self.config.engines[engine_name].particle_emission_rate
        	particle_system:setEmissionRate(emission_rate * self.accelerate)
        end
        -- self.particle_emitter_left:setEmissionRate(100.0)
        -- self.particle_emitter_right:setEmissionRate(100.0)
	else
        for engine_name, particle_system in pairs(self.engine_particle_systems) do
        	particle_system:setEmissionRate(0.0)
        end
        -- self.particle_emitter_left:setEmissionRate(0.0)
        -- self.particle_emitter_right:setEmissionRate(0.0)
    end
	
	-- Back, left or right (all involve turning)
    if self.turn_back then
        local travelling_angle = math.atan2(self.vel_y, self.vel_x)
        local target_angle = travelling_angle + math.pi
        local ideal_turn = geometry.shortest_angle_to_angle(self.angle, target_angle)
        if ideal_turn > (self.config.turn_rate * dt) then
            ideal_turn = self.config.turn_rate * dt
        elseif ideal_turn < (-self.config.turn_rate * dt) then
            ideal_turn = -self.config.turn_rate * dt
        end
        self.angle = self.angle + ideal_turn
    else
        if self.turn_right then
            self.angle = self.angle + self.config.turn_rate * dt
        end
        if self.turn_left then
            self.angle = self.angle - self.config.turn_rate * dt
        end
    end
    
    if self.target_angle then
        local ideal_turn = geometry.shortest_angle_to_angle(self.angle, self.target_angle)
        if ideal_turn > (self.config.turn_rate * dt) then
            ideal_turn = self.config.turn_rate * dt
        elseif ideal_turn < (-self.config.turn_rate * dt) then
            ideal_turn = -self.config.turn_rate * dt
        end
        self.angle = self.angle + ideal_turn
    end
    
    -- Update position from velocity
    self.pos_x = self.pos_x + (self.vel_x * dt)
    self.pos_y = self.pos_y + (self.vel_y * dt)
    
    -- Update particle thing
    for engine_name, particle_system in pairs(self.engine_particle_systems) do
    	local engine_config = self.config.engines[engine_name]
    	local engine_x, engine_y = unpack(engine_config.position)
    	particle_system:setPosition(self:local_to_world(engine_x, engine_y))
        local emission_vel_x = self.vel_x + math.cos(self.angle + math.pi) * 500
	    local emission_vel_y = self.vel_y + math.sin(self.angle + math.pi) * 500
	    local emission_angle = math.atan2(emission_vel_y, emission_vel_x)
	    local emission_speed = math.sqrt(emission_vel_x ^ 2 + emission_vel_y ^ 2)
	    particle_system:setDirection(emission_angle)
		particle_system:setSpeed(emission_speed)
	    particle_system:update(dt)
    end
end

function ship.Ship.local_to_world(self, x, y)
	-- Convert point to wold space. Rotate:
	local new_x = x * math.cos(self.angle) - y * math.sin(self.angle)
	local new_y = x * math.sin(self.angle) + y * math.cos(self.angle)
	return new_x + self.pos_x, new_y + self.pos_y
end
	
return ship
