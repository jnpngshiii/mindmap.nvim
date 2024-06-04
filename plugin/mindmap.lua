--------------------
-- User functions
--------------------

----------
-- Node
----------

vim.api.nvim_create_user_command("Mindmap_Add_VisualSelection_As_ExcerptNode", function()
	vim.api.nvim_input("<Esc>") -- TODO: remove this workaround
	require("mindmap").Mindmap_Add_VisualSelection_As_ExcerptNode()
end, {})
vim.api.nvim_set_keymap(
	"v",
	"E",
	"<cmd>Mindmap_Add_VisualSelection_As_ExcerptNode<cr>",
	{ noremap = true, silent = true }
)

vim.api.nvim_create_user_command("Mindmap_Add_NearestHeading_As_HeadingNode", function()
	require("mindmap").Mindmap_Add_NearestHeading_As_HeadingNode()
end, {})

----------
-- Edge
----------

vim.api.nvim_create_user_command("Mindmap_Add_SimpleEdge_From_LatestAddedNode_To_NearestHeadingNode", function()
	require("mindmap").Mindmap_Add_SimpleEdge_From_LatestAdd_edNode_To_NearestHeadingNode()
end, {})

vim.api.nvim_create_user_command("Mindmap_Add_SelfLoopContentEdge_From_NearestHeadingNode_To_Itself", function()
	require("mindmap").Mindmap_Add_SelfLoopContentEdge_From_NearestHeadingNode_To_Itself()
end, {})

vim.api.nvim_create_user_command("Mindmap_Add_SelfLoopSubheadingEdge_From_NearestHeadingNode_To_Itself", function()
	require("mindmap").Mindmap_Add_SelfLoopSubheadingEdge_From_NearestHeadingNode_To_Itself()
end, {})

----------
-- Database
----------

vim.api.nvim_create_user_command("Mindmap_Save_AllMindmaps", function()
	require("mindmap").Mindmap_Save_AllMindmaps()
end, {})
vim.api.nvim_create_autocmd("VimLeave", {
	callback = function()
		require("mindmap").Mindmap_Save_AllMindmaps()
	end,
})

--------------------
-- Debug functions
--------------------

vim.api.nvim_create_user_command("Mindmap_Test", function()
	require("mindmap").Mindmap_Test()
end, {})
