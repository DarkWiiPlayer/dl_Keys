local schema = require "lapis.db.schema"
local types = schema.types

return {
	function()
		schema.create_table ("keys", {
			{"id", types.text};
			{"path", types.text};
			{"starts", types.time};
			{"ends", types.time};
			{"max_clicks", types.integer};
			{"clicks", types.integer};
			
			"PRIMARY KEY (id)";
		})
	end;
}