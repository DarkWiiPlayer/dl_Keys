#!/usr/local/bin/lua
local keys = require( ("keys.%s"):format(arg[1] or "file") )

-- print "Time format as lua code!"

-- Get user input
local function inputs()
	local function f(s) return #s>0 and s end
	local function d(s)
		local valid,_, year, month, day, hour, miute, second
			= s:find "(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d):(%d%d)"
		if not valid then return nil end
		local t = os.time{
			year=tonumber(year);
			month=tonumber(month);
			day=tonumber(day);
			hour=tonumber(hour);
			minute=tonumber(minute);
			second=tonumber(second);
		}
		return t
	end
	local n = tonumber
	io.write "What path?: "
		local path = io.read()
	io.write "Custom key?: "
		local key = io.read()
	io.write "When shall it expire?: "
		local ends = io.read()
	io.write "When does it start?: "
		local starts = io.read()
	io.write "How many clicks?: "
		local max_clicks = io.read()
	
	return{path=f(path), key=f(key), ends=d(ends), starts=d(starts), max_clicks=n(max_clicks)}
end

-- Do stuff

local keylist = keys.load()
local key = keys.new(inputs())
print(key)
io.write "Save this key? (Y/n): "
	local res = io.read()
if res=="" or res=="y" or res=="Y" then
	keylist[key.key] = key
	if keys.save(keylist) then
		print "Key saved :)"
	else
		print "Error saving key!"
	end
else
	print "Key was NOT saved"
end
return 0

--[[
for key_str, key in pairs(keylist) do
	print(key)
end
--]]