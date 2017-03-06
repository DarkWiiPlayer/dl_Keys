local keys = require "lapis.db.model".Model:extend("keys")

local lib = {}
local keylen = 5

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

local function time(time)
	local _, _, year, month, day, hour, minute, second =
		time:find "(%d%d%d%d)-(%d%d)-(%d%d) (%d%d):(%d%d):(%d%d)"
	return os.time { year=year, month=month, day=day, hour=hour, minute=minute, second=second }
end

local function is_sub_dir(sub_dir, dir)
  return sub_dir:gsub("/&", ""):gsub("/?$", "/"):find(dir:gsub("/?$", "/"):gsub("^/?", "/")) and true or false
end

local function is_valid(key)
	local e = keys:find(key)
	if not e then return false end
  -- Is the key too old?
  if (time(key.ends) < os.time()) and (time(key.ends) > 0) then return false end
  -- Has it been used too many times?
  if key.max_clicks > 0 then
    if key.clicks >= key.max_clicks then return false end
  end
  return true
end

-- **Interface / Front-end**

lib.is_sub_dir = is_sub_dir

function lib.is_usable(key, path)
  -- Is the key `nil`?
  if not key then return nil, "no key" end
  -- Is the key invalid or has it expired?
  if not is_valid(key) then return false, "invalid" end
  
  -- Has the key lifetime started yet?  
  if time(key.starts) > os.time() then return false, "not valid yet" end
  
  -- If dir is provided, does the key apply to it?
  if type(path)=="string" then
    return is_sub_dir(path, key.path)
  end
  
  return true
end

function lib.use(key, path)
  if not lib.is_usable(key, path) then return key end
  
  key.clicks = key.clicks + 1
	
	print(("Used key %s to access %s"):format(key.key, path))
  
  return true
end

function lib.new(key)
  local new = setmetatable({}, _key_meta)
  
  new.path = key.path or "/"
  new.key = key.key or generate_key(keylen)
  new.starts = key.starts or os.time()
  new.ends = key.ends or 0
  new.clicks = 0
  new.max_clicks = key.max_clicks or 0
  
  return new
end

-- debugging stuff --
--[[
local k = read_keys(keyfile) or {}

-- k[#k+1]=lib.new({path="/new", key=generate_key(10), starts=os.time(), ends=os.time()+120*60, max_clicks=20})
-- checks go here --
print(lib.use(k["B5127C6C37F4187AA719"], "/new"))
print(k["B5127C6C37F4187AA719"])
write_keys(keyfile, k)
--]]

return lib
