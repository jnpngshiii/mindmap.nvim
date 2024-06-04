--------------------
-- User functions
--------------------

vim.api.nvim_create_user_command("MindmapAddTheLatestVisualSelectionAsAnExcerptNodeToGraph", function()
	vim.api.nvim_input("<Esc>") -- TODO: remove this workaround
	require("mindmap").MindmapAddTheLatestVisualSelectionAsAnExcerptNodeToGraph()
end, {})

vim.api.nvim_create_user_command("MindmapAddTheNearestHeadingAsAnHeadingNodeToGraph", function()
	require("mindmap").MindmapAddTheNearestHeadingAsAnHeadingNodeToGraph()
end, {})

vim.api.nvim_create_user_command("MindmapAddSelfLoopContentEdgeToNearestHeadingNode", function()
	require("mindmap").MindmapAddSelfLoopContentEdgeToNearestHeadingNode()
end, {})

vim.api.nvim_create_user_command("MindmapSaveAllMindmapsInDatabase", function()
	require("mindmap").MindmapSaveAllMindmapsInDatabase()
end, {})

--------------------
-- Debug functions
--------------------

vim.api.nvim_create_user_command("MindmapTest", function()
	require("mindmap").MindmapTest()
end, {})

--------------------
-- (Auto) Commands
--------------------

vim.api.nvim_set_keymap(
	"v",
	"me",
	"<cmd>MindmapAddTheLatestVisualSelectionAsAnExcerptNodeToGraph<cr>",
	{ noremap = true, silent = true }
)

vim.api.nvim_create_autocmd("VimLeave", {
	callback = function()
		require("mindmap").MindmapSaveAllMindmapsInDatabase()
	end,
})
