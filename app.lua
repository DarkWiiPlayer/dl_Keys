local lapis = require "lapis"
local configuration = require("lapis.config").get()
local app = lapis.Application()
--local keys = require "keys"

app:enable("etlua")
app.layout = false

app:before_filter(function(self)
  self.nav = {"Front page", "About", "Download"}
  self.configuration = configuration;
end)

app:get("front_page", "/", function(self)
  return {self:html(function(env)
    h1 "Main Page"
    p "Nothing to see here, move along!"
    p(function() 
      text "Here's a link: "
      a{"google.de", href="//google.de"}
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

app:get("download", "/download", function(self)
  return {
    self:html(function(self)
      h1 "Download section"
      p "This is where you download files (duh)"
    end);
    layout = "layout";
  }
end)

app:get("download_file", "/download/*", function(self)
  
  -- Start by checking permissions
  if false then -- todo: add files that don't need code
    return {"Error 724: This line should be unreachable!", status=724}
  elseif not self.params.key then
    return { self:html(function()
      h1 "Access Denied"
      p "Please provide a key with access clearance for this file!"
      end);
      layout = "layout";
    }
  elseif not true then
    return "fuck you"
  end
  
  -- Try gzipped files first

  -- |important| todo: check for Accept-Encoding header
  local file, err, errn = io.open("files/"..self.params.splat..".gz")
  if file then
    local input = file:read "*a"
    return {
      input;
      content_type = "text/plain";
      headers = {
        ["content-encoding"]="gzip";
      };
    }
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
