local target = chat -- iris.Table({4})
-- target = getmetatable( target )

-- this file is intended for printing out the values of globals
-- simply set the value of the target variable and paste the file into the console

function print_table_contents(tbl: {})
    for i, v in pairs(tbl) do
        print(i, v)
    end
end

print("value:")
print(target,  " : ", type(target))

if type(target) ~= "table" and type(target) ~= "userdata" then
    return
end

print("")
local metatable = getmetatable(target)
if type(metatable) ~= "table" then
    print(`meta: {metatable}`)
else
    print(`meta:`)
    print_table_contents(metatable)
end


local str = ""
for i, v in pairs( target ) do
	local out_type = type(v)
	if out_type == "table" then
		out_type = "{[unknown]: unknown}"
	elseif out_type == "function" then
		out_type = "(...unknown) -> ...unknown"
	end
    str ..= `{i}: {out_type},\n`
end
print("")
print("to paste:")
print(str)

print("")
print("contents:")
print_table_contents(target)
