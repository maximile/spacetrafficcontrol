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
	
	return self
end

function ship.Ship.update(self, dt)
	-- Handle inputs. Forwards:
	if self.accelerate then
		local speed_change = self.acceleration * dt
        self.vel_x = self.vel_x + math.cos(self.angle) * speed_change
        self.vel_y = self.vel_y + math.sin(self.angle) * speed_change
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
end

return ship
