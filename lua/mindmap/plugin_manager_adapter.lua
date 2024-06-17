local plugin_data = require("mindmap.plugin_data")

local plugin_manager_adapter = {}

function plugin_manager_adapter.setup(user_config)
	user_config = user_config or {}

	plugin_data.config = vim.tbl_extend("force", plugin_data.config, user_config)
end

return plugin_manager_adapter
