-- run this file in the deadline client console

if shared.speedometer then
	shared.speedometer.destroy()
end

type history_data = {
	position: Vector3,
	timestamp: number,
}

type row_data = {
	name: string,
	generate_widget: () -> nil,
}

local time_passed = 0
local history_length = 500

local history: {history_data} = {}
for i=1, history_length do
	history[i] = {
		position = Vector3.zero,
		timestamp = 0,
	}
end

local states = {}
for i=1, history_length do
	states[i] = iris.State(0)
end

function velocity_from_datapoints(earlier: history_data, later: history_data): number
	local delta_time = later.timestamp - earlier.timestamp
	local delta_pos = later.position - earlier.position
	return delta_pos.Magnitude / delta_time
end
function get_velocity_over_frames(frame_count: number): number
	local start_frame = history[#history - frame_count]
	local end_frame = history[#history]

	return velocity_from_datapoints(start_frame, end_frame)
end

local table_rows: {row_data} = {}
table.insert(table_rows, {
	name = `velocity this frame`,
	generate_widget = function()
		local velocty = get_velocity_over_frames(1)
		iris.Text(`{velocty}`)
	end
})
table.insert(table_rows, {
	name = `velocity over last 10 frames`,
	generate_widget = function()
		local velocty = get_velocity_over_frames(10)
		iris.Text(`{velocty}`)
	end
})
table.insert(table_rows, {
	name = `velocity over last 100 frames`,
	generate_widget = function()
		local velocty = get_velocity_over_frames(100)
		iris.Text(`{velocty}`)
	end
})
table.insert(table_rows, {
	name = `velocity over last 250 frames`,
	generate_widget = function()
		local velocty = get_velocity_over_frames(100)
		iris.Text(`{velocty}`)
	end
})
table.insert(table_rows, {
	name = `velocity over last {history_length-1} frames`,
	generate_widget = function()
		local velocty = get_velocity_over_frames(history_length-1)
		iris.Text(`{velocty}`)
	end
})

function update_gui_state()
	for i, state in pairs(states) do
		local current_datapoint = history[i]
		local next_datapoint = history[i+1]

		if not next_datapoint then
			return
		end

		local velocity = velocity_from_datapoints(current_datapoint, next_datapoint)
		state:set(velocity / 50)
	end
end

local heartbeat = time.heartbeat("speedometer", function(delta_time: number)
	if not framework.character.is_alive() then
		return
	end

	time_passed += delta_time

	local current_position = framework.character.get_position()

	-- insert to the end
	table.insert(history, {
		position = current_position,
		timestamp = time_passed,
	})
	-- remove from the start
	table.remove(history, 1)

	update_gui_state()
end)

local iris_disconnect = iris:Connect(function()
	iris.Window({"Speedometer"})
		-- table
		iris.Table({2})
		for _, row in pairs(table_rows) do
			iris.Text(row.name)
			iris.NextColumn()
			row.generate_widget()
			iris.NextColumn()
		end
		iris.End()

		-- for i, state in pairs(states) do
		-- 	iris.ProgressBar({`{i}`}, {progress = state})
		-- end
	iris.End()
end)
-- local iris_connection = iris:Connect(iris.ShowDemoWindow)

shared.speedometer = {
	destroy = function()
		heartbeat:Disconnect()
		iris_disconnect()
	end
}
