local lib = {}

local keyfile = ".keys"

function lib.set_keyfile(kf)
  keyfile = kf or keyfile
  return lib
end

--[[
#   Key format:
  {
    path:string
    key:string
    starts:date
    ends:date
    max_clicks:n
    clicks:n
  }
  
#   Todo list:
  2016-10-06
  - Read Keys --done
  - Write Keys --done
  - `__tostring` metamethod for keys --done
  - implement key object integrity check --done
  2016-10-07
  - Check for key validity --done
  2016-10-08
  - Use key
--]]

-- **Data Access / Back-end**

local fields = {"path", "key", "starts", "ends", "max_clicks", "clicks"}

local _key_meta = {
  __tostring = function(self)
    local result = ""
    for index, value in ipairs(fields) do
      result = result .. value .. " = " .. (self[value] or "")
      if index < #fields then result = result .. "\n" end
    end
    return result
  end;
}

local function genKey(length)
  math.randomseed(os.time())
  local str = ""
  for i=1,length do
    str = str..("%X"):format(math.random(0,255))
  end
  return str
end

local function check_data_integrity(key)
  -- Key must have all the needed fields fields
  for index, field in ipairs(fields) do
    if not key[field] then return false end
  end
  
  -- Key must not have expired
  if (tonumber(key.ends) or 0) < os.time() then return false end
  
  -- Key must not have too many clicks
  if (tonumber(key.max_clicks) or 0)>0 then
    if (tonumber(key.clicks) or 0) > tonumber(key.max_clicks) then return false end
  end
  
  return true
end

local function read_keys(filename)
  local keys = {}
  local file = io.open(filename)
  if not file then return nil, "Could not open key file for reading" end
  for line in file:lines() do
    local key = setmetatable({}, _key_meta)
    local i=1; for thing in line:gmatch"[^\t]+" do
      if fields[i] then key[fields[i]]=thing end
      i = i + 1
    end
    table.insert(keys, key)
  end
  file:close()
  
  return keys
end

local function write_keys(filename, keys)
  local file = io.open(filename, "w")
  if not file then return nil, "Could not open file" end
  ----
  for _, key in ipairs(keys) do
    if check_data_integrity(key) then
      for index, field in ipairs(fields) do
        file:write(key[field])
        if index<#fields then file:write "\t" end
      end
      file:write("\n")
    end
  end
  ----
  file:close()
  return true;
end

local function match_dir(path, directory)
  return directory:find("^/?"..path:match"^/?(.-)/?&")
end

-- **Interface / Front-end**

local function is_sub_dir(sub_dir, dir)
  print(sub_dir)
  print(dir:gsub("/$", ""):gsub("^/?", "^/?"))
  return sub_dir:gsub("/&", ""):find(dir:gsub("/$", ""):gsub("^/?", "^/?")) and true or false
end

function lib.is_valid_key(key, path)
  -- Is the key invalid or has it expired?
  if not check_data_integrity(key) then return false end
  
  -- Has the key lifetime started yet?
  if (tonumber(key.starts)) < os.time() then return false end
  
  -- If dir is provided, does the key apply to it?
  if type(path)=="string" then
    return is_sub_dir(path, key.path)
  end
  
  return true
end

-- debugging stuff --
local k = read_keys(keyfile) or {}
k[#k+1]=setmetatable({path="/", key=genKey(10), starts=os.time(), ends=os.time()+120, max_clicks=20, clicks=0}, _key_meta)

return lib