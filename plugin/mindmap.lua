--------------------
-- User functions
--------------------

vim.api.nvim_create_user_command("MindmapAddTheLatestVisualSelectionAsAnExcerptNodeToGraph", function()
	require("mindmap").MindmapAddTheLatestVisualSelectionAsAnExcerptNodeToGraph()
end, {})

vim.api.nvim_create_user_command("MindmapAddTheNearestHeadingAsAnHeandingNodeToGraph", function()
	require("mindmap").MindmapAddTheNearestHeadingAsAnHeandingNodeToGraph()
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
	":<cmd>MindmapAddTheLatestVisualSelectionAsAnExcerptNodeToGraph<cr>",
	{ noremap = true, silent = true }
)
