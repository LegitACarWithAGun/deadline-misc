local invis_body_color = Color3.new(1, 1, 1)
local invis_body_transparency = 0.5
local invis_weapon_transparency = 0.9

local clothing_names = {
	"item",
	"nvg",
	"mount"
}

function handle_r6_basepart(part: luauInstance)
	part.Color = invis_body_color
	part.Transparency = invis_body_transparency

	-- print(part.Name)
	for _, child in pairs(part.get_descendants()) do
		-- print(`	- {sub.Name}`)

		if (table.find(clothing_names, child.Name)) then
			child.destroy()
		end
	end
end

function handle_weapon(part: luauInstance)
	for _, desc in pairs(part.get_descendants()) do
		if desc.is_a("BasePart") then
			desc.Transparency = invis_weapon_transparency
		end
	end
end

function make_invisible(player_id: number)
	local model = get_chars_root().find_first_child(tostring(player_id))
	if not model then
		warn(`did not find model for player with id {player_id}`)
	end

	for _, child in pairs(model.get_children()) do
		if child.Name == "humanoid_root_part" or child.Name == "hitbox" then
			continue
		end

		if (child.Name == "prepared_weapon") then
			handle_weapon(child)
			continue
		end
		if child.is_a("BasePart") then
			handle_r6_basepart(child)
			continue
		end

		print(`unhandled character model part: {child}`)
	end
end

on_server_event:Connect(function(args: {})
	if args[1] ~= "invis_player" then
		return
	end
	make_invisible(args[2])
end)
