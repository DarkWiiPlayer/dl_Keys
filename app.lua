local lapis = require "lapis"
local configuration = require("lapis.config").get()
local app = lapis.Application()
local keys = require "keys.file"

app:enable("etlua")
app.layout = false

app:before_filter(function(self)
  self.nav = {"Front page", "About", "Downloads"}
  self.configuration = configuration;
  self.keys = keys.load()
  -- ADMIN KEY --
  self.keys["administrator"]=keys.new{key="administrator", path="/"}
end)

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

app:get("downloads", "/download", function(self)
  return {
    self:html(function(self)
      h1 "Download section"
      p "This is where you download files (duh)"
    end);
    layout = "layout";
  }
end)

--[[
#Actual file downloads
--]]

app:get("download", "/download/*", function(self)
  
  -- Start by checking permissions
  if false then -- |todo|: add files that don't need code
    return {"Error 724: This line should be unreachable!", status=724}
  elseif not self.params.key then
    return { self:html(function()
      h1 "Access Denied"
      p "Please provide a key with access clearance for this file!"
      end);
      layout = "layout";
      status=403;
    }
  elseif not keys.use(self.keys[self.params.key], self.params.splat) then
    return { self:html(function()
      h1 "Access Denied"
      p "Please provide a key with access clearance for this file!"
      p(("The key you have provided (%s) is invalid"):format(self.params.key))
      end);
      layout = "layout";
      status=403;
    }
  end
  
  -- Try gzipped files first

  -- |important| todo: check for Accept-Encoding header
  local file, err, errn = io.open("files/"..self.params.splat..".gz")
  if file then
    if self.req.headers["Accept-Encoding"]:find("gzip") then
      local input = file:read "*a"
      return {
        input;
        content_type = "text/plain";
        headers = {
          ["content-encoding"]="gzip";
        };
      }
    else
      file, err, errn = io.open("files/"..self.params.splat)
      if file then
        local input = file:read "*a"
        file:close()
        return input
      else
        return {
          "The server has no unzipped version of this file stored!";
          content_type = "text/plain";
        }
      end
    end
  end
  
  -- Try normal file if no gzipped file can be found
  
  file, err, errn = io.open("files/"..self.params.splat)
  if file then
    local input = file:read "*a"
    file:close()
    return input
  else
    self.no_footer=true
    self.msg="The file you are trying to download does not exist"
    return {render="404", layout="layout", status=404}
  end
end)



--[[
#==File section==
This is where the user will see information about files and get a download link
|todo|: implement /lol
--]]

app:get("file", "/file/*", function(self)
  return {
    self:html(function(self)
      p1 "this section is totally not implemented :P"
    end);
  }
end)



--[[
#==About page==
feel free to change this, but of course a link to my [website](http://www.darkwiiplayer.com/) is always welcome :)
--]]

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

app.handle_404 = function(self)
  self.no_footer=true
  self.msg="You were trying to access something you shouldn't :("
  return {render="404", layout="layout", status=404}
end

return app
