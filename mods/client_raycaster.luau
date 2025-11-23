if shared.legit_raycaster then
	shared.legit_raycaster.destroy()
end

local shoot_ray_keybind = Enum.KeyCode.L
local line_thickness = 0.1
local end_size = 0.3

local part_line = create_instance("Part")
local part_end = create_instance("Part")
function setup_visulization_parts()
	-- set common properties
	for i, part in pairs( {part_line, part_end} ) do
		-- prevent it from interacting with anything else
		part.CanCollide = false
		part.CanQuery = false

		-- visual attributes
		part.Color = Color3.new(1, 0, 0)
		part.Anchored = true
		part.Material = Enum.Material.Neon
		part.Transparency = 0.75
	end

	-- line
	part_line.Shape = Enum.PartType.Cylinder
	-- end
	part_end.Shape = Enum.PartType.Ball
	part_end.Size = Vector3.new(end_size, end_size, end_size)
end
setup_visulization_parts()

function draw_line(start: CFrame, distance: number)
	-- places the line in the middle of the path
	part_line.CFrame = start + start.LookVector * (distance/2)
	-- rotate so the part's X axis is the long side, for compatability with Enum.PartType.Cylinder
	part_line.CFrame *= CFrame.Angles(0, math.rad(90), 0)

	-- stretches the part to cover the entire path
	part_line.Size = Vector3.new(distance, line_thickness, line_thickness)

	-- place end
	part_end.CFrame = start + start.LookVector * distance

	-- finish up
	part_line.Parent = get_chars_root()
	part_end.Parent = get_chars_root()
end

function format_vector3(v3: Vector3?)
	if not v3 then
		return "nil"
	end

	return string.format("Vector3(%.4f, %.4f, %.4f)", v3.X, v3.Y, v3.Z)
end

function raycast_from_camera()
	local params = query.create_raycast_params()
	-- params.filter_descendants_instances( {get_chars_root()} )
	
	local cam_cframe = framework.character.get_camera_cframe()
	local results = query.raycast(cam_cframe.Position, cam_cframe.LookVector * 999999999, params)

	info("raycast results:")
	print(`- distance: {results.distance}`)
	print(`- instance: {results.instance}`)
	print(`- material: {results.material}`)
	print(`- normal: {format_vector3(results.normal)}`)
	print(`- start position: {format_vector3(cam_cframe.Position)}`)
	print(`- end position: {format_vector3(results.position)}`)
	
	draw_line(cam_cframe, results.distance)
end

local input_group = InputGroup.new()
input_group:bind_key(
	raycast_from_camera,
	InputType.Began,
	false,           	-- ignore game processed
	shoot_ray_keybind   -- keycode
)

shared.legit_raycaster = {
	destroy = function()
		input_group:disconnect_all_binds()

		part_line.destroy()
		part_end.destroy()
	end
}
