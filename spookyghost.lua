local spookyghost = {}

function spookyghost.new(x, y, r, g, b)
	local ghost = {pos_x=x, pos_y=y, col_r=r, col_g=g, col_b=b, health=1.0,
				   harmed=false}
	return ghost
end

return spookyghost
