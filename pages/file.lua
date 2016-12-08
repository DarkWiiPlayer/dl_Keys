local util = require"lapis.util"
local keys = require "keys.file"

local function file_is(path, t)
	return os.execute(('[ -%s "%s" ]'):format(t, path)) == 0
end

local function deny(msg) return {
	layout="layout";
	status=403;
	msg or "Access Denied!";
} end

return function(self)
  self.virtual = "/" .. util.unescape(self.params.splat or "")
  do
    local key = self.keys[self.params.key]
    self.access = keys.is_usable(key) and key.path
  end
  
  if not self.access then return deny "Access denied: Please provide a valid access key!" end
  
--[[
#Serve the Information
At this point everything should be set up correctly
--]]

  if file_is("files"..self.virtual, "d") then -- Directory
    if keys.is_sub_dir(self.virtual, self.access) then -- Full Access
      self.access = nil;
      return {
        layout="layout";
        render=true;
      }
    elseif keys.is_sub_dir(self.access, self.virtual) then -- Subdirectory Access
      return {
        layout="layout";
        render=true;
      }
    else
      return deny("Access denied! (Wrong key)")
    end
  elseif file_is("files"..self.virtual, "f") then
    return {
      layout="layout";
      render="download";
    }
  else
    return {
      status=404;
      render="404";
      layout="layout";
    }
  end
end