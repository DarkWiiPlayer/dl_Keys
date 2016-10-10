local lapis = require "lapis"
local configuration = require("lapis.config").get()
local app = lapis.Application()
local keys = require "keys.file"

app:enable("etlua")
app.layout = false

app:before_filter(function(self)
  self.nav = {"Front page", "About"}
  self.configuration = configuration;
  self.keys = keys.load()
  -- ADMIN KEY --
  self.keys["administrator"]=keys.new{key="administrator", path="/"}
  self.lib_keys = keys
end)

--[[
#Meta
These are the sections that provide information to the user
--]]

app:get("front_page", "/", function(self)
  return {self:html(function(env)
    h1 "Main Page"
    p "This is where you can put your content; a brief explanation of who you are, or what files you want to share and why, etc."
    h2 "Project Roadmap"
    ul(function(self)
      li "Add directory index"
      li "Add permissions to directory index"
      li "Add a way to add keys via web interface"
    end)
  end);
  layout="layout";
  }
end)

app:get("about", "/about", function(self)
  return {self:html(function(env)
    h1 "About dl_Keys"
    p "dl_Keys is a web-app built on top of the lapis web framework that serves files for downloads protected by download keys."
    p "The idea is that every key applies to a single file or directory, allowing access to that file or an subdirectory (and its files)"
    p "A key can have a limited lifespan: it can have an expiration date, a limited number of clicks or even both"
    p(function() 
      text "Author: "
      a{"DarkWiiplayer", href="//darkwiiplayer.com"}
    end)
  end);
  layout="layout";
  }
end)

--[[
#==Download Section==
This is where files are actually downloaded
See _file section_ for information about files
--]]

--[[ -- |DEBUG| Never leave this enabled in a production environment!
app:get("keys", "/keys", function(self)
  local t = {content_type="text/plain"}
  for key_str, key in pairs(self.keys) do
    table.insert(t, tostring(key).."\n".."\n")
  end
  return t
end)
--]]

app:get("download", "/download(/*)", function(self)
  return "go back"
end)


--[[
#==File section==
This is where the user will see information about files and get a download link
--]]

app:get("file", "/file(/*)", function(self)
--[[
#Initial Setup
--]]
  local function file_is(path, t) return os.execute(('[ -%s "%s" ]'):format(t, path)) == 0 end
  self.virtual = "/" .. (self.params.splat or "")
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
#Serve the data
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
