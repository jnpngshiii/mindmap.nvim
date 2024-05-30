local lineNum = vim.api.nvim_win_get_cursor(0)[1]
local backseatNamespace = vim.api.nvim_create_namespace("backseat")

local function get_highlight_group()
	-- return vim.g.backseat_highlight_group
	return "String"
end

vim.api.nvim_buf_set_extmark(0, backseatNamespace, lineNum - 1, 0, {
	virt_text_pos = "overlay",
	virt_lines = {
		{ { "1", get_highlight_group() } },
	},
	hl_mode = "combine",
	sign_text = "T",
	sign_hl_group = get_highlight_group(),
})

-- Clear all backseat virtual text and signs
vim.api.nvim_create_user_command("BClear", function()
	vim.api.nvim_buf_clear_namespace(0, backseatNamespace, 0, -1)
end, {})

-- Clear backseat virtual text and signs for that line
vim.api.nvim_create_user_command("BClearLine", function()
	local lineNum = vim.api.nvim_win_get_cursor(0)[1]
	vim.api.nvim_buf_clear_namespace(0, backseatNamespace, lineNum - 1, lineNum)
end, {})
