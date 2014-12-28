local autopilot = {}

autopilot.Autopilot = {}

function autopilot.Autopilot.new(ship)
	local self = setmetatable({}, autopilot.Autopilot)
	self.ship = ship
	return self
end

function autopilot.Autopilot.update(self, dt)
	-- Not enabled? Don't do anything.
	if self.enabled ~= true then
		return
	end
	
	-- Enabled but target is nil? Slow to a stop.
	
end
	
