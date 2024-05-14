--------------------
-- Excerpt Functions
--------------------

vim.api.nvim_create_user_command("MindmapCreateExcerptUsingVisualSelection", function()
	require("mindmap").create_excerpt_using_latest_visual_selection()
end, {})

--------------------
-- Mindmap Functions
--------------------

vim.api.nvim_create_user_command("MindmapSaveMindmapInCurrentBuf", function()
	require("mindmap").save_mindmap_in_current_buf()
end, {})

--------------------
-- Logger Functions
--------------------

vim.api.nvim_create_user_command("MindmapShowLogCache", function()
	require("mindmap").show_log_in_log_cache()
end, {})

vim.api.nvim_create_user_command("MindmapShowLogFile", function()
	require("mindmap").show_log_in_log_file()
end, {})
