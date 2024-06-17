local user_func = require("mindmap.user_func")
local plugin_manager_adapter = require("mindmap.plugin_manager_adapter")

-- TODO: update this to use the new plugin_manager_adapter
user_func.setup = plugin_manager_adapter.setup

return user_func
