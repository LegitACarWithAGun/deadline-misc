-- run this file in the deadline server console

-- INSTRUCTIONS:
-- ;spawn_set :: set the default spawn, does not reset overrides
-- ;spawn_set <username> :: set the spawn for a specific player (this is henchforth reffered to as a spawn override)
-- ;spawn_clear :: remove all spawn locations, reverts to default deadline spawns
-- ;spawn_clear DEFAULT :: remove only the default spawn, keeping overrides
-- ;spawn_clear OVERRIDE :: remove all spawn overrides
-- ;spawn_clear <username> :: remove the specific player's spawn override
-- ;spawn_list :: prints all the spawn conditions in the console


-- load command bot
if not shared.dlcomp_command_bot then
    require("https://raw.githubusercontent.com/LegitACarWithAGun/deadlinecomp-mods/refs/heads/main/command-bot.luau")
end

-- load arg parser module
if not shared.dlcomp_parser then
    require("https://raw.githubusercontent.com/LegitACarWithAGun/deadlinecomp-mods/refs/heads/main/arg-parser.luau")
end

local default_spawn: Vector3?
local spawn_overrides: {[string]: Vector3} = {}

function format_vector3(v3: Vector3?)
	if not v3 then
		return "nil"
	end

	return string.format("Vector3(%.2f, %.2f, %.2f)", v3.X, v3.Y, v3.Z)
end

function print_players_with_override()
	warn("the following players still have a spawn override:")
	for name, _ in pairs(spawn_overrides) do
		print(name)
	end
end

on_player_spawned:Connect(function(player_name: string)
	local player = players.get(player_name)
	if not player then
		warn(`player [{player_name}] spawned but doesnt have a player object`)
		return
	end

	local override = spawn_overrides[player_name]
	if override then
		player.set_position(override)
	end

	if default_spawn then
		player.set_position(default_spawn)
	end
end)

shared.dlcomp_command_bot.add_command("spawn_set", "set the spawn for everyone, or a specific player", function(args: string, extra: any)
	if not extra.caller.is_alive() then
		chat.send_announcement(`you arent alive (you are: [{extra.caller.name}])`)
		return
	end

	local want_position = extra.caller.get_position()
	local target_player, parse_info = shared.dlcomp_parser.get_player(args)

	-- no player specified, set default spawn
	if parse_info.converted_from == "" then
		default_spawn = want_position
		chat.send_announcement(`default spawn set`)
		return
	end

	-- unknown player specified
	if not target_player then
		chat.send_announcement(`target player with name [{parse_info.converted_from}] not found`)
		return
	end

	-- set the spawn override for the target player
	spawn_overrides[target_player.name] = want_position
	chat.send_announcement(`spawn override set for [{target_player.name}]`)
end)

shared.dlcomp_command_bot.add_command("spawn_clear", "remove spawn conditions, accepts the following paths: (none), DEFAULT, OVERRIDE, <username>", function(args: string, extra: any)
	if not extra.caller.is_alive() then
		chat.send_announcement(`you arent alive (you are: [{extra.caller.name}])`)
		return
	end

	local path, _ = shared.dlcomp_parser.get_string(args)

	if path == "" then
		-- nothing was passed, remove all spawn conditions
		default_spawn = nil
		spawn_overrides = {}
		chat.send_announcement(`all spawn conditions removed, its like nothing even happened..`)
		return

	elseif path == "DEFAULT" then
		-- remove only the default spawn
		default_spawn = nil

		-- announce in chat, print the players that still have an override in the console
		chat.send_announcement(`removed the default spawn location, check console for players that still have a spawn override`)
		print_players_with_override()

		return

	elseif path == "OVERRIDE" then
		-- remove only the player overrides
		spawn_overrides = {}

		chat.send_announcement(`removed all spawn overrides`)
		if default_spawn then
			chat.send_announcement(`WARNING: the default spawn is still set`)
		end

		return

	end

	-- get the target player
	local target_player, parse_info = shared.dlcomp_parser.get_player(args)
	if not target_player then
		chat.send_announcement(`target player with name [{parse_info.converted_from}] not found`)
		return
	end

	-- remove the target player's spawn override
	spawn_overrides[target_player.name] = nil
	chat.send_announcement(`removed [{target_player.name}]'s spawn override, check console for players that still have a spawn override`)
	print_players_with_override()
end)

shared.dlcomp_command_bot.add_command("spawn_list", "prints all the spawn conditions in console", function()
	warn("spawn conditions:")

	print(`DEFAULT: {format_vector3(default_spawn)}`)

	for name, location in pairs(spawn_overrides) do
		print(`[{name}]: {format_vector3(location)}`)
	end

	chat.send_announcement(`spawn conditions printed into the console`)
end)

-- run this file in the deadline server console