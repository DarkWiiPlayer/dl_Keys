local config = require "lapis.config"

local _verion_meta = {
  __tostring = function(self)
    return "test"
    --return ("%i.%i.%i"):format(self[1], self[2], self[3])
  end;
}

config({"development", "production"}, {
  -- CHANGE THESE!
  secret = "secret";
  session_name = "session_name";
  version = "0.3.1"
})

config("development", {
  port = 8080;
  ssl_port = 9090;
  session_name = "awesome_session_dev";
})

config("production", {
  code_cache = "on";
  port = 80;
  ssl_port = 443;
})