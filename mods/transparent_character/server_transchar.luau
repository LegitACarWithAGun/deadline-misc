-- example server side for transparent characters, doing the bare minimum
-- only the clients are capable of setting a player's model invisible
-- the server needs to do the following things:
-- - keep track of who should be invisible
-- - whenever that player spawns, tell every other player to set that player invisible
-- - whenever a new player joins, tell them to set all of the currentyl invisible players.. invisible

-- load command bot
if not shared.dlcomp_command_bot then
    require("https://raw.githubusercontent.com/LegitACarWithAGun/deadlinecomp-mods/refs/heads/main/command-bot.luau")
end
-- load arg parser module
if not shared.dlcomp_parser then
    require("https://raw.githubusercontent.com/LegitACarWithAGun/deadlinecomp-mods/refs/heads/main/arg-parser.luau")
end

local invisible_players = {}
local player_index = "name"

function is_invisible(target: player)
	return table.find(invisible_players, target[player_index])
end
function toggle_invisible(target: player, toggle: boolean?)
	if toggle == nil then
		toggle = not is_invisible(target)
	end

	if toggle then
		table.insert(invisible_players, target[player_index])
		bounce(target)
	else
		local index = table.find(invisible_players, target[player_index])
		table.remove(invisible_players, index)
	end
end

-- send a network message to a specific player to render another player as invisible
function send_message(receiver: player, target: player)
	receiver.fire_client("invis_player", target.player_id)
end
-- tell every player to render a target player as invisible
function bounce(target: player)
	for _, receiver in pairs(players.get_all()) do
		if receiver.id == target.id then
			continue
		end
		send_message(receiver, target)
	end
end

-- invisibility doesnt persist through death, reapply it when a invisible player respawns
on_player_spawned:Connect(function(player_name: string)
	local player = players.get(player_name)
	if is_invisible(player) then
		bounce(player)
	end
end)

-- remove player from list if they leave, would memleak otherwise
on_player_left:Connect(function(player_name: string)
	local player = players.get(player_name)
	toggle_invisible(player, false)
end)

-- when a player joins the server, we need to catch them up with who is currently invisible
on_player_joined:Connect(function(player_name: string)
	local receiver = players.get(player_name)
	for _, alive in players.get_alive() do
		if is_invisible(alive) then
			send_message(receiver, alive)
		end
	end
end)

shared.dlcomp_command_bot.add_command("invis", "toggle the invisibility of the specified player", function(args: string, extra: any)
	local target_player, info = shared.dlcomp_parser.get_player(args)
	if not target_player then
		chat.send_announcement("please specify a player")
		return
	end
	local toggle, _ = shared.dlcomp_parser.get_bool(info.remaining_text)

	toggle_invisible(target_player, toggle)
end)
shared.dlcomp_command_bot.add_command("invis_all", "toggle the visiblity of all player", function(args: string, extra: any)
	local toggle = shared.dlcomp_parser.get_bool(args)
	for _, player in players.get_all() do
		toggle_invisible(player, toggle)
	end
end)
