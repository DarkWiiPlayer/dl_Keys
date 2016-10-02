local lib = {}

--[[
  KEY FORMAT
  {
    key:string
    expires:date
    created:date
  }
--]]

function lib.get(directory)
  -- Given a directory, returns a list of all keys that apply to it
  -- TODO: Implement
  return {{key="master";expires=0;created=0}} -- TODO: add data!
end

function lib.add(directory, Key)
  local key, expires
  if Key then
    key = Key.key or "master" -- TODO: add key generation
    expires = Key.expires or 0 -- TODO: add default (current + read from settings)
  else
    -- TODO: Same as above
    key = "master"
    expires = 0
  end
  
  -- Given a directory, adds a key to it
  return "master" -- TODO: Should return the newly generated key
end

return lib