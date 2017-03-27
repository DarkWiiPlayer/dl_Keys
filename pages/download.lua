local util = require"lapis.util"
local keys = require "keys.file"

return function(self)
	do
    local key = self.params.key
    self.access = keys.use(key)
  end
	
  local function file_is(path, t) return os.execute(('[ -%s "%s" ]'):format(t, path)) == 0 end
  self.virtual = "/" .. util.unescape(self.params.splat or "")
	if file_is("files"..self.virtual, "d") then self.virtual = self.virtual:gsub("[^/]$", "%1/") end
	-- In lua 5.3 this is equivalent to :gsub("/?$", "/") but in 5.1 this doesn't work =/
	-- |TODO| confirm this
  do
    local key = self.keys[self.params.key]
    self.access = keys.is_usable(key) and key.path
  end
  local function deny(msg) return {
    layout="layout";
    status=403;
    msg or "Access Denied!";
  } end
  
  local function serve_file(name)
    local file = io.open(name)
    if not file then print "Could not read file" return { status="500", "Internal server error" } end
    
    local content = file:read("*a")
		if not keys.use(self.keys[self.params.key]) then return "consistency error!\nKey passed initial validity check but keys.use returned false =/" end
		keys.save(self.keys)
    
    return {
      content;
      content_type="other";
      headers = {
        ["content-length"]=#content;
      }
    }
  end
  
  if not self.access then return deny "Access denied: Please provide a valid access key!" end
  if not keys.is_usable(key, self.virtual) then deny "Access denied: Key does not apply!" end
  
  if file_is("files"..self.virtual, "d") then
    return { redirect_to=self:url_for("file", {splat=self.params.splat}, {key=self.params.key}) }
    
  elseif file_is("files"..self.virtual, "f") then
    return serve_file("files"..self.virtual)
  else
    return "weird error" -- not really
  end
  
end