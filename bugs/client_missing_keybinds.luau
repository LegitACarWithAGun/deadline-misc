-- run in the client console

-- gather All defined keybinds
local keybind_found = {}
for id, info in config.keybinds do
	keybind_found[id] = false
end

-- look through keybinds menu
for _, row in config.settings_layout.keybinds do
	if row.type ~= "keybind" then
		continue
	end

	local name = row.keybind
	-- check for unexpected state
	if keybind_found[name] ~= false then
		-- TODO: warn doesnt work on client for some reason
		info(`weird state: {name} {keybind_found[name]}`)
	end

	keybind_found[name] = true
end

-- format and output results
for name, found in keybind_found do
	if found then
		continue
	end
	local data = config.keybinds[name]
	print(`{name}:`)
	print(`	- human: {data.name}`)
	print(`	- description: {data.description}`)
	local default = data.default[1] or {}
	print(`	- default type: {default.input_type}`)
	print(`	- default key: {default.key_code}`)
end
