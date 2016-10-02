local config = require "lapis.config"

config({"development", "production"}, {
  -- CHANGE THESE!
  secret = "secret";
  session_name = "session_name";
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