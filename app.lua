local lapis = require("lapis")
local app = lapis.Application()

app:enable("etlua")
app.layout = false

app:get("/", function(self)
  return {self:html(function(env)
    h1 "Main Page"
    p "Nothing to see here, move along"
  end);
  layout="layout";
  }
end)

app:get("file", "/file/*", function(self)
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

app.handle_404 = function(self)
  self.no_footer=true
  self.msg="You were trying to access something you shouldn't :("
  return {render="404", layout="layout", status=404}
end

return app
