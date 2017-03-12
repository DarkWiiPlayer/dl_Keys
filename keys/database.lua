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
	if not time then return nil end
	local _, _, year, month, day, hour, minute, second =
		time:find "(%d+)-(%d?%d)-(%d?%d)%s+(%d?%d):(%d?%d):(%d?%d)"
	return os.time { year=year, month=month, day=day, hour=hour, minute=minute, second=second }
end

local function is_sub_dir(sub_dir, dir)
  return sub_dir:gsub("/&", ""):gsub("/?$", "/"):find(dir:gsub("/?$", "/"):gsub("^/?", "/")) and true or false
end

local function get_key(key)
	key = keys:find(key)
	if not key then return false, "Key cannot be nil", 0 end
  -- Is the key too old?
  if (time(key.ends) < os.time()) and (time(key.ends) > 0) then return false, "This key has expired", 1 end
  -- Has it been used too many times?
  if key.max_clicks > 0 then
    if key.clicks >= key.max_clicks then return false, "Activation limit reached.", 2 end
  end
  return key
end

-- **Interface / Front-end**

lib.is_sub_dir = is_sub_dir

function lib.is_usable(key, path)
  -- Is the key invalid or has it expired?
  local msg, err; key, msg, err = get_key(key)
	if not key then return false, "invalid" end
  
  -- Has the key lifetime started yet?
  if time(key.starts) > os.time() then return false, "not valid yet" end
  
  -- If dir is provided, does the key apply to it?
  if type(path)=="string" then
    return is_sub_dir(path, key.path) and key
  end
  
  return false
end

function lib.use(key, path)
	key = lib.is_usable(key, path)
  if not key then return nil end
  
	key.clicks = key.clicks + 1
	key:update("clicks")
	
	print(("Used key %s to access %s"):format(key.id, path))
  
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

return lib
