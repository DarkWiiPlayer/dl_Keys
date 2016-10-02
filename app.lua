local lapis = require("lapis")
local app = lapis.Application()

app:enable("etlua")
app.layout = false

app:get("/", function(self)
  return self:html(function(env)
    h1 "Main Page"
    p "Nothing to see here, move along"
  end)
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
    return {err, status=404}
    -- DEBUG
    -- VULNERABILITY[PROBING]
  end
end)

return app
