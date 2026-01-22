-- run this file in the deadline server console
-- fits: https://www.youtube.com/watch?v=CJHEuJwtjEM

-- INSTRUCTIONS:
-- treat SYNO as survivors, ANTO as infected
-- when infection is active, any SYNO that dies will be switched to ANTO, and ANTO's loadout gets overriden to only be a knife in their primary
-- 
-- ;infect <COUNT> :: switching COUNT amount of people from SYNO to ANTO, and start the round of infection if it isnt already, specify 0 if you want to start without switching anyone
-- ;infect_end :: disables the team switching and loadout overriding inherit to infection, this automatically gets run every time the round ends
-- ;toggle_infect_respawn <toggle> :: when a admin infects a random person, should that person be respawned or transform in-place

-- CAUTION:
-- prevents manually switching teams
sharedvars.gm_team_balancing_threshold = -1


if shared.legit_infection then
	shared.legit_infection.destroy()
end

-- load command bot
if not shared.dlcomp_command_bot then
    require("https://raw.githubusercontent.com/LegitACarWithAGun/deadlinecomp-mods/refs/heads/main/command-bot.luau")
end
-- load arg parser module
if not shared.dlcomp_parser then
    require("https://raw.githubusercontent.com/LegitACarWithAGun/deadlinecomp-mods/refs/heads/main/arg-parser.luau")
end

local module = {
	team_infected = "attacker",
	team_survivor = "defender",

	respawn_on_infect = false,

	event_spawn = nil,
	event_die = nil,
}
local active = false

function get_alive_in_team(team: string)
	local output = {}
	for _, player in players.get_alive() do
		if player.get_team() == team then
			table.insert(output, player)
		end
	end
	return output
end

function set_infected_loadout(player: player)
	for _, slot in pairs({"primary", "secondary", "throwable1", "throwable2"}) do
		player.set_weapon(slot, "nothing")
	end
	player.set_weapon("primary", "M9", "[]")
end

function infect_random_survivors(count: number)
	for i=1, count do
		local survivors = get_alive_in_team(module.team_survivor)
		if #survivors < 1 then
			chat.send_announcement("no survivors to infect")
			return
		end
		
		local chosen = survivors[ math.random(#survivors) ]
		chosen.set_team(module.team_infected)

		if module.respawn_on_infect then
			chosen.respawn()
			chat.send_announcement(`{chosen.name} has been infected and respawned`)
		else
			set_infected_loadout(chosen)
			chat.send_announcement(`{chosen.name} has been infected`)
		end
	end
end

function start_round(infected_count: number)
	if active then
		infect_random_survivors(infected_count)
		return
	end

	chat.send_announcement("enabling infected")
	active = true

	-- choose players to switch to infected team
	infect_random_survivors(infected_count)

	-- strip infected of anything other than knives
	module.event_spawn = on_player_spawned:Connect(function(player_name: string)
		local player = players.get(player_name)
		set_infected_loadout(player)
	end)

	module.event_die = on_player_died:Connect(function(player_name: string)
		local player = players.get(player_name)
		if player.get_team() == module.team_survivor then
			player.set_team(module.team_infected)
			chat.send_announcement(`{player.name} has fallen to the horde`)
		end
	end)
end
function end_round()
	if module.event_spawn then
		module.event_spawn:Disconnect()
	end
	if module.event_die then
		module.event_die:Disconnect()
	end

	if active then
		chat.send_announcement("disabled infection")
		active = false
	end
end

gamemode.finished:Connect(end_round)

shared.dlcomp_command_bot.add_command("infect", "infect random survivors", function(args: string, extra: any)
	local infected_count, _ = shared.dlcomp_parser.get_number(args)
	if (infected_count == nil) then
		chat.send_announcement("include how many infected to spawn")
		return
	end

	start_round(infected_count)
end)
shared.dlcomp_command_bot.add_command("infect_end", "end the current round of infection", end_round)
shared.dlcomp_command_bot.add_command("toggle_infect_respawn", "whether admin-triggered infections should respawn the player", function(args: string, extra: any)
	local want, _ = shared.dlcomp_parser.get_bool(args)

	want = want == nil and not module.respawn_on_infect or want
	module.respawn_on_infect = want
	chat.send_announcement(`respawn_on_infect = {want}`)
end)

module.destroy = end_round
shared.legit_infection = module