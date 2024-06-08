--------------------
-- User functions
--------------------

----------
-- Node
----------

vim.api.nvim_create_user_command("MindmapAddVisualSelectionAsExcerptNode", function()
	-- TODO: remove this workaround
	vim.api.nvim_input("<Esc>")
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

vim.api.nvim_create_user_command("MindmapShowExcerpt", function()
	require("mindmap").MindmapShowExcerpt()
end, {})

vim.api.nvim_create_user_command("MindmapShowAllExcerpt", function()
	require("mindmap").MindmapShowAllExcerpt()
end, {})

vim.api.nvim_create_user_command("MindmapCleanExcerpt", function()
	require("mindmap").MindmapCleanExcerpt()
end, {})

vim.api.nvim_create_user_command("MindmapCleanAllExcerpt", function()
	require("mindmap").MindmapCleanAllExcerpt()
end, {})

vim.api.nvim_create_user_command("MindmapAddSimpleEdgeFromLatestAddedNodeToNearestHeadingNode", function()
	require("mindmap").MindmapAddSimpleEdgeFromLatestAddedNodeToNearestHeadingNode()
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
