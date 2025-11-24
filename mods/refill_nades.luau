-- run this file in the deadline server console

local YOU = players.get( function_caller )

YOU.set_health(100)
for _, slot in pairs( {"secondary", "throwable1", "throwable2"} ) do
	YOU.set_weapon(slot, "F1", "[]")
end

-- run this file in the deadline server console