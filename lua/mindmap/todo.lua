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

-- TODO: Interesting, but not useful.

--- Wrap a function with a wrapping function.
---@param wrapping_func function The function used to wrap.
---@param wrapped_func function The function to be wrapped.
---@return function
local function wrap_func(wrapping_func, wrapped_func)
	return function(...)
		wrapping_func(wrapped_func, ...)
	end
end

--- Wrap all functions in a table with a wrapping function recursively.
---@param wrapping_func function The function used to wrap.
---@param wrapped_tbl table The table to be wrapped.
---@return table
local function wrap_table(wrapping_func, wrapped_tbl)
	for key, value in pairs(wrapped_tbl) do
		-- print("Checking key: " .. key .. " type: " .. type(value))
		if type(value) == "function" and key ~= "init" then
			-- print("    Wraping function: " .. key)
			wrapped_tbl[key] = M.wrap_func(wrapping_func, value)
		elseif type(value) == "table" then
			if key == "__index" then
				-- print("    Skip __index")
				wrapped_tbl[key] = value
			else
				wrapped_tbl[key] = M.wrap_table(wrapping_func, value)
			end
		end
	end
	return wrapped_tbl
end
