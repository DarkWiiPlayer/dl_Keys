local lib = {}

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
  - implement key object integrity check
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

local keyfile = ".keys"

function lib.add(directory, key)
  local keys,err = read_keys(keyfile)
  if not keys then return nil, err end
  
  table.insert(keys, key)
  --table.sort(keys, function(a,b) return a.dir<b.dir end) -- **TODO**: Improve
  
  print("Writing "..#keys.." keys...")
  return write_keys(keyfile, keys)
end

function lib.remove(filter)
  
  local keys,err = read_keys(keyfile)
  if not keys then return nil, err end
  
  local result = {}
  for _, key in ipairs(keys) do
    if (not filter.path or filter.path==key.path) and
    (not filter.key or filter.path==key.key) and
    (not filter.expires or filter.path==key.expires) and
    (not filter.created or filter.path==key.created) then
      table.insert(result,key)
    end
  end
  
  return write_keys(keyfile, result) -- this _should_ lead to a proper tail call
end

function lib.can_access(keystr, directory)
  -- |broken| todo: actually check that the directory maches too
  -- |broken| todo: check that the key is actually valid!
  local keys = read_keys(keyfile)
  for index, key in ipairs(keys) do
    if keystr == key.key then return true end
  end
  return false
end


local k = read_keys(keyfile) or {}
k[#k+1]=setmetatable({path="/", key=genKey(10), starts=os.time(), ends=os.time()+20, max_clicks=20, clicks=0}, _key_meta)
write_keys(keyfile, k)
print(#k)
print(k[#k])

return lib