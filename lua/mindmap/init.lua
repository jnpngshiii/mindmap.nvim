local plugin_data = require("mindmap.plugin_data")
local user_func = require("mindmap.user_func")

local M = {}

---Setup function for the Mindmap plugin
---@param user_config table User configuration table
function M.setup(user_config)
	user_config = user_config or {}

	-- Merge user config with default config
	plugin_data.config = vim.tbl_deep_extend("force", plugin_data.config, user_config)

	-- Set up default keymaps if enabled
	if plugin_data.config.enable_default_keymap then
		M.setup_default_keymaps()
	end

	-- Set up shorten keymaps if enabled
	if plugin_data.config.enable_shorten_keymap then
		M.setup_shorten_keymaps()
	end

	-- Set up default autocommands if enabled
	if plugin_data.config.enable_default_autocmd then
		M.setup_default_autocommands()
	end
end

function M.setup_default_keymaps()
	local keymap_prefix = plugin_data.config.keymap_prefix

	-- MindmapAdd (Node)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "an",
		"<cmd>MindmapAddNearestHeadingAsHeadingNode<CR>",
		{ noremap = true, silent = true, desc = "Add nearest heading as heading node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "ae",
		"<cmd>MindmapAddVisualSelectionAsExcerptNode<CR>",
		{ noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
	)
	vim.api.nvim_set_keymap(
		"v",
		"E",
		"<cmd>MindmapAddVisualSelectionAsExcerptNode<CR>",
		{ noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
	)

	-- MindmapRemove (Node)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "rn",
		"<cmd>MindmapRemove nearest node<CR>",
		{ noremap = true, silent = true, desc = "Remove nearest node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "rN",
		"<cmd>MindmapRemove buffer node<CR>",
		{ noremap = true, silent = true, desc = "Remove buffer node" }
	)

	-- MindmapLink (Edge)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "ll",
		"<cmd>MindmapLink latest SimpleEdge nearest<CR>",
		{ noremap = true, silent = true, desc = "Add SimpleEdge from latest node to nearest node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "ls",
		"<cmd>MindmapLink nearest SelfLoopSubheadingEdge nearest<CR>",
		{ noremap = true, silent = true, desc = "Add SelfLoopSubheadingEdge to nearest node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "lc",
		"<cmd>MindmapLink nearest SelfLoopContentEdge nearest<CR>",
		{ noremap = true, silent = true, desc = "Add SelfLoopContentEdge to nearest node" }
	)

	-- MindmapUnlink (Edge)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "u",
		"<cmd>MindmapUnlink nearest<CR>",
		{ noremap = true, silent = true, desc = "Unlink nearest edge" }
	)

	-- MindmapDisplay
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "dc",
		"<cmd>MindmapDisplay nearest card_back<CR>",
		{ noremap = true, silent = true, desc = "Display nearest card back" }
	)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "de",
		"<cmd>MindmapDisplay nearest excerpt<CR>",
		{ noremap = true, silent = true, desc = "Display nearest excerpt" }
	)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "ds",
		"<cmd>MindmapDisplay nearest sp_info<CR>",
		{ noremap = true, silent = true, desc = "Display nearest spaced repetition info" }
	)

	-- MindmapClean
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "c",
		"<cmd>MindmapClean nearest all<CR>",
		{ noremap = true, silent = true, desc = "Clean all virtual text for nearest node" }
	)

	-- MindmapReview
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "r",
		"<cmd>MindmapReview buffer<CR>",
		{ noremap = true, silent = true, desc = "Review cards in current buffer" }
	)

	-- MindmapUndo/Redo
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "z",
		"<cmd>MindmapUndo<CR>",
		{ noremap = true, silent = true, desc = "Undo last mindmap operation" }
	)
	vim.api.nvim_set_keymap(
		"n",
		keymap_prefix .. "Z",
		"<cmd>MindmapRedo<CR>",
		{ noremap = true, silent = true, desc = "Redo last undone mindmap operation" }
	)
end

function M.setup_shorten_keymaps()
	local shorten_prefix = plugin_data.config.shorten_keymap_prefix

	-- Remap 'm' to 'M' for marks if 'm' is used as prefix
	if shorten_prefix == "m" then
		vim.api.nvim_set_keymap("n", "M", "m", { noremap = true })
	end

	-- MindmapAdd (Node)
	vim.api.nvim_set_keymap(
		"n",
		shorten_prefix .. "a",
		"<cmd>MindmapAddNearestHeadingAsHeadingNode<CR>",
		{ noremap = true, silent = true, desc = "Add nearest heading as node" }
	)

	-- MindmapLink (Edge)
	vim.api.nvim_set_keymap(
		"n",
		shorten_prefix .. "l",
		"<cmd>MindmapLink latest SimpleEdge nearest<CR>",
		{ noremap = true, silent = true, desc = "Link latest to nearest" }
	)
	vim.api.nvim_set_keymap(
		"n",
		shorten_prefix .. "s",
		"<cmd>MindmapLink nearest SelfLoopSubheadingEdge nearest<CR>",
		{ noremap = true, silent = true, desc = "Self-link subheading" }
	)
	vim.api.nvim_set_keymap(
		"n",
		shorten_prefix .. "c",
		"<cmd>MindmapLink nearest SelfLoopContentEdge nearest<CR>",
		{ noremap = true, silent = true, desc = "Self-link content" }
	)

	-- MindmapDisplay
	vim.api.nvim_set_keymap(
		"n",
		shorten_prefix .. "d",
		"<cmd>MindmapDisplay nearest all<CR>",
		{ noremap = true, silent = true, desc = "Display all for nearest" }
	)

	-- MindmapReview
	vim.api.nvim_set_keymap(
		"n",
		shorten_prefix .. "r",
		"<cmd>MindmapReview buffer<CR>",
		{ noremap = true, silent = true, desc = "Review buffer" }
	)
end

function M.setup_default_autocommands()
	vim.api.nvim_create_autocmd("VimLeave", {
		callback = function()
			user_func.MindmapSave("all")
		end,
		desc = "Save all mindmap graphs on exit",
	})

	if plugin_data.config.show_excerpt_after_add then
		vim.api.nvim_create_autocmd("User", {
			pattern = "MindmapNodeAdded",
			callback = function()
				user_func.MindmapDisplay("latest", "excerpt")
			end,
			desc = "Show excerpt after adding a node",
		})
	end

	if plugin_data.config.show_excerpt_after_bfread then
		vim.api.nvim_create_autocmd("BufRead", {
			pattern = "*.norg",
			callback = function()
				user_func.MindmapDisplay("buffer", "excerpt")
			end,
			desc = "Show excerpts after reading a Neorg buffer",
		})
	end
end

return M
