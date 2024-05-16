--------------------
-- Excerpt Functions
--------------------

vim.api.nvim_create_user_command("MindmapCreateExcerptUsingVisualSelection", function()
	require("mindmap").create_excerpt_using_latest_visual_selection()
end, {})

vim.api.nvim_create_user_command("MindmapShowUnusedExcerptIds", function()
	require("mindmap").show_unused_excerpt_ids()
end, {})

--------------------
-- Mindnode Functions
--------------------

vim.api.nvim_create_user_command("MindmapAddLastCreatedExcerptToNearestMindnode", function()
	require("mindmap").add_last_created_excerpt_to_nearest_mindnode()
end, {})

--------------------
-- Mindmap Functions
--------------------

vim.api.nvim_create_user_command("MindmapSaveMindmapInCurrentBuf", function()
	require("mindmap").save_mindmap_in_current_buf()
end, {})

vim.api.nvim_create_user_command("MindmapLoadMindmapInCurrentBuf", function()
	require("mindmap").load_mindmap_in_current_buf()
end, {})
