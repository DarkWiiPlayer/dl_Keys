local lapis = require "lapis"
local configuration = require("lapis.config").get()
local app = lapis.Application()
local keys = require "keys.file"
local util = require"lapis.util"

app:enable("etlua")
app.layout = false

app:before_filter(function(self)
  self.nav = {"Front page", "About", "File"}
  self.configuration = configuration;
  self.keys = keys.load()
  -- ADMIN KEY --
  self.masterkey = "administrator" -- |todo|: move this to the configuration
  self.lib_keys = keys
	self.unescape = util.unescape
end)

--[[
#Meta
These are the sections that provide information to the user
--]]

app:get("front_page", "/", function(self)
  return {
		render=true;
		layout="layout";
  }
end)

app:get("about", "/about", function(self)
  return {
		render=true;
		layout="layout";
  }
end)

--[[
#==Download Section==
This is where files are actually downloaded
See _file section_ for information about files
--]]

app:get("download", "/download(/*)", function(self)
  local function file_is(path, t) return os.execute(('[ -%s "%s" ]'):format(t, path)) == 0 end
  self.virtual = "/" .. util.unescape(self.params.splat or "")
	if file_is("files"..self.virtual, "d") then self.virtual = self.virtual:gsub("[^/]$", "%1/") end
	-- In lua 5.3 this is equivalent to :gsub("/?$", "?") but in 5.1 this doesn't work =/
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
  
end)


--[[
#==File section==
This is where the user will see information about files and get a download link
--]]

app:get("file", "/file(/*)", function(self)
  local function file_is(path, t) return os.execute(('[ -%s "%s" ]'):format(t, path)) == 0 end
  self.virtual = "/" .. util.unescape(self.params.splat or "")
  do
    local key = self.keys[self.params.key]
    self.access = keys.is_usable(key) and key.path
  end
  local function deny(msg) return {
    layout="layout";
    status=403;
    msg or "Access Denied!";
  } end
  
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
end)


--[[
#Other lapis magic
error handling and all that
--]]

app.handle_404 = function(self)
  self.no_footer=true
  self.msg="You were trying to access something you shouldn't :("
  return {render="404", layout="layout", status=404}
end

return app
