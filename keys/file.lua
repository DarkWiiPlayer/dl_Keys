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
  - Check data integrity while reading --done
  - ⤷ Remove integrity check when writing --done
  - Change keys from index->data to key->data --done
  - ⤷ Change `ipairs` to `pairs` where needed --done
  - Use key --done
--]]

-- **Data Access / Back-end**

local fields = {
--{name, function}; where function is applied to the data after reading it in as a string
  {"path", tostring};
  {"key", tostring};
  {"starts", tonumber};
  {"ends", tonumber};
  {"max_clicks", tonumber};
  {"clicks", tonumber};
}

local _key_meta = {
  __tostring = function(self)
    local result = ""
    for index, field in ipairs(fields) do
      result = result .. field[1] .. " = " .. (self[field[1]] or "")
      if index < #fields then result = result .. "\n" end
    end
    return result
  end;
}
local _keys_meta = {
  __tostring = function(self)
    return "bitch" -- |todo|: implement
  end;
}

local function generate_key(length)
  math.randomseed(os.time())
  local str = ""
  for i=1,length do
    str = str..("%02X"):format(math.random(0,255))
  end
  return str
end

local function check_data_integrity(key)
  -- Key must have all the needed fields fields
  for index, field in ipairs(fields) do
    if not key[field[1]] then return false end
  end
  return true
end

local function is_valid(key)
  -- Is the data intact?
  if not check_data_integrity(key) then return false end
  -- Is the key too old?
  if (key.ends < os.time()) and (key.ends > 0) then return false end
  -- Has it been used too many times?
  if key.max_clicks > 0 then
    if key.clicks > key.max_clicks then return false end
  end
  return true
end

local function read_keys(filename)
  local keys = setmetatable({}, _keys_meta)
  local file = io.open(filename)
  if not file then return nil, "Could not open key file for reading" end
  ----
  for line in file:lines() do
    local key = setmetatable({}, _key_meta)
    local i=1; for thing in line:gmatch"[^\t]+" do
      thing = fields[i][2](thing)
      if (thing == "") or not thing then goto next end
      if fields[i] then key[fields[i][1]]=thing end
      i = i + 1
    end
    if is_valid(key) then keys[key.key]=key end
    ::next::
  end
  ----
  file:close()
  
  return keys
end

local function write_keys(filename, keys)
  local file = io.open(filename, "w")
  if not file then return nil, "Could not open file" end
  ----
  for key_str, key in pairs(keys) do
    for index, field in ipairs(fields) do
      file:write(key[field[1]])
      if index<#fields then file:write "\t" end
    end
    file:write("\n")
  end
  ----
  file:close()
  return true;
end

local function is_sub_dir(sub_dir, dir)
  return sub_dir:gsub("/&", ""):find(dir:gsub("/$", ""):gsub("^/?", "^/?")) and true or false
end

-- **Interface / Front-end**

function lib.load_keys()
  return read_keys(keyfile)
end
function lib.save_keys(keys)
  return write_keys(keyfile, keys)
end

function lib.is_usable(key, path)
  -- Is the key `nil`?
  if not key then return nil, "no key" end
  -- Is the key invalid or has it expired?
  if not is_valid(key) then return false, "invalid" end
  
  -- Has the key lifetime started yet?  
  if key.starts > os.time() then return false, "not valid yet" end
  
  -- If dir is provided, does the key apply to it?
  if type(path)=="string" then
    return is_sub_dir(path, key.path)
  end
  
  return true
end

function lib.use(key, path)
  if not lib.is_usable(key, path) then return false end
  
  key.clicks = key.clicks + 1
  
  return true
end

function lib.create(key)
  local new = setmetatable({}, _key_meta)
  
  new.path = key.path or "/"
  new.key = key.key or generate_key(20)
  new.starts = key.starts or os.date()
  new.ends = key.ends or 0
  new.clicks = 0
  new.max_clicks = key.max_clicks or 0
  
  return new
end

-- debugging stuff --
--[[
local k = read_keys(keyfile) or {}

-- k[#k+1]=lib.create({path="/new", key=generate_key(10), starts=os.time(), ends=os.time()+120*60, max_clicks=20})
-- checks go here --
print(lib.use(k["B5127C6C37F4187AA719"], "/new"))
print(k["B5127C6C37F4187AA719"])
write_keys(keyfile, k)
--]]

return lib