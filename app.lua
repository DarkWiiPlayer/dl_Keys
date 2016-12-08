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

app:get("download", "/download(/*)", require"pages.download")

app:get("file", "/file(/*)", require"pages.file")


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
