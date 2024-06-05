--------------------
-- User functions
--------------------

----------
-- Node
----------

vim.api.nvim_create_user_command("MindmapAddVisualSelectionAsExcerptNode", function()
	vim.api.nvim_input("<Esc>") -- TODO: remove this workaround
	require("mindmap").MindmapAddVisualSelectionAsExcerptNode()
end, {})
vim.api.nvim_set_keymap("v", "E", "<cmd>MindmapAddVisualSelectionAsExcerptNode<cr>", { noremap = true, silent = true })

vim.api.nvim_create_user_command("MindmapAddNearestHeadingAsHeadingNode", function()
	require("mindmap").MindmapAddNearestHeadingAsHeadingNode()
end, {})

vim.api.nvim_create_user_command("MindmapRemoveNearestHeadingNode", function()
	require("mindmap").MindmapRemoveNearestHeadingNode()
end, {})

----------
-- Edge
----------

vim.api.nvim_create_user_command("MindmapAddSimpleEdgeFromLatestAddedNodeToNearestHeadingNode", function()
	require("mindmap").MindmapAddSimpleEdgeFromLatestAdd_edNodeToNearestHeadingNode()
end, {})

vim.api.nvim_create_user_command("MindmapAddSelfLoopContentEdgeFromNearestHeadingNodeToItself", function()
	require("mindmap").MindmapAddSelfLoopContentEdgeFromNearestHeadingNodeToItself()
end, {})

vim.api.nvim_create_user_command("MindmapAddSelfLoopSubheadingEdgeFromNearestHeadingNodeToItself", function()
	require("mindmap").MindmapAddSelfLoopSubheadingEdgeFromNearestHeadingNodeToItself()
end, {})

----------
-- Database
----------

vim.api.nvim_create_user_command("MindmapSaveAllMindmaps", function()
	require("mindmap").MindmapSaveAllMindmaps()
end, {})
vim.api.nvim_create_autocmd("VimLeave", {
	callback = function()
		require("mindmap").MindmapSaveAllMindmaps()
	end,
})

--------------------
-- Debug functions
--------------------

vim.api.nvim_create_user_command("MindmapTest", function()
	require("mindmap").MindmapTest()
end, {})
