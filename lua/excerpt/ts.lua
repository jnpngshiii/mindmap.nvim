local neorg = require("neorg.core")
local ts_utils = require("nvim-treesitter.ts_utils")

---@alias ts_node any|userdata
---@alias ts_tree any|userdata

local M = {}

--- Get an unique id.
---@return string
local function get_unique_id()
	return string.format("%s%d", os.time(), math.random(0000, 9999))
end

--- Replace the text of a node.
---@param text string|table<string>
---@param node ts_node
---@param bufnr integer?
---@return nil
function M.replace_node_text(text, node, bufnr)
	if type(text) == "string" then
		text = { text }
	end
	if not bufnr then
		bufnr = 0
	end

	local start_row, start_col, end_row, end_col = node:range()
	vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, text)
end

--- Get the text of a node.
---@param node ts_node
---@param bufnr integer?
---@return string
function M.get_node_text(node, bufnr)
	if not bufnr then
		bufnr = 0
	end

	return vim.treesitter.get_node_text(node, bufnr)
end

--- Get the nearest heading node at the cursor.
---@return ts_node
function M.get_nearest_heading_node()
	local current_node = ts_utils.get_node_at_cursor()

	while not current_node:type():match("^heading%d$") do
		current_node = current_node:parent()
	end

	return current_node
end

--- Get the nearest heading node level at the cursor.
---@return string
function M.get_nearest_heading_node_level()
	local nearest_heading_node = M.get_nearest_heading_node()
	local level = string.match(nearest_heading_node:type(), "heading(%d)")
	return level
end

--- Get the nearest heading node id at the cursor.
---@return string
function M.get_nearest_heading_node_id()
	local heading_query = [[
      (heading1
        title: (paragraph_segment) @title
        content: (_) @content
      )
    ]]

	local nearest_heading_node = M.get_nearest_heading_node()
	local matched_query = neorg.utils.ts_parse_query("norg", heading_query)

	for index, node in matched_query:iter_captures(nearest_heading_node, 0) do
		local capture_name = matched_query.captures[index]
		if capture_name == "title" then
			local title = M.get_node_text(node)
			local id = string.match(title, "%d%d%d%d%d%d%d%d%d%d%d%d%d%d")
			-- TODO: Warn user if multiple ids are found.
			if not id then
				id = get_unique_id()
				M.replace_node_text(title .. " %" .. id .. "%", node)
			end
			return id
		end
	end

	return nil
end

if true then
	print(M.get_nearest_heading_node_id())
end

return M
