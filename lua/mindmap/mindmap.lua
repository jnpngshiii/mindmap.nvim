local logger = require("mindmap.logger")
local mindnode = require("mindmap.mindnode")

local M = {}

---@alias logger.Logger Logger
---@alias mindnode.Mindnode Mindnode

--------------------
-- Class Mindmap
--------------------

---@class Mindmap
---@field json_path string Path to the JSON file used to store the mindmap.
---@field mnode_table table<string, Mindnode> Mindnodes in the mindmap.
---@field logger Logger Logger of the mindmap. NOTE: Logger should have a method log(msg, msg_level).
M.Mindmap = {
	json_path = "",
	mnode_table = {},
	-- logger = nil,
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindmap:init(obj)
	obj = obj or {}
	obj.json_path = obj.json_path or self.json_path
	obj.mnode_table = obj.mnode_table or self.mnode_table
	obj.logger = obj.logger or self.logger
	if obj.logger then
		obj.logger:log("[Logger] Init logger.", "info")
	end

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Add an mindnode to the mindmap.
---@param mnode Mindnode
---@return nil
function M.Mindmap:add(mnode)
	self.mnode_table[mnode.mnode_id] = mnode
end

---Pop an mindnode from the mindmap.
---@param id string ID of the mindnode to pop.
---@return Mindnode|nil
function M.Mindmap:pop(id)
	local poped_mindnode = self.mnode_table[id]
	if poped_mindnode == nil then
		vim.api.nvim_out_write("No mindnode found. Nothing to pop.\n")
		return nil
	end

	-- vim.api.nvim_out_write("Pop an mindnode from mindmap.\n")
	self.mnode_table[id] = nil
	return poped_mindnode
end

---Remove an mindnode from the mindmap.
---@param index number
---@return nil
function M.Mindmap:remove(index)
	local remove_mindnode = self.mnode_table[index]
	if remove_mindnode == nil then
		vim.api.nvim_out_write("No mindnode found. Nothing to remove.\n")
	end

	-- vim.api.nvim_out_write("Remove an mindnode from mindmap.\n")
	self.mnode_table[index] = nil
end

---Find mindnode(s) in the mindmap.
---@param timestamp string|string[]
---@return Mindnode|Mindnode[]
function M.Mindmap:find(timestamp)
	if type(timestamp) ~= "table" then
		if type(timestamp) == "string" then
			return self.mnode_table[timestamp]
		end
	end

	local found_mindnodes = {}
	for _, v in pairs(timestamp) do
		found_mindnodes[v] = self:find(v)
	end
	return found_mindnodes
end

---Save the mindmap to a JSON file.
---@return nil
function M.Mindmap:save()
	local json_context = {}
	for _, mnode in pairs(self.mnode_table) do
		if mnode:check_health() then
			json_context[#json_context + 1] = mnode.to_table(mnode)
		else
			self:log("[Mindmap] Invalid mindnode (" .. mnode.mnode_id .. "), skip saving.", "error")
		end
	end
	json_context = vim.fn.json_encode(json_context)

	local json, err = io.open(self.json_path, "w")
	if not json then -- TODO:
		self:log("[Mindmap] Could not save mindmap at: " .. self.json_path, "error")
		error("Could not open file: " .. err)
	end

	json:write(json_context)
	json:close()
end

---Load the mindmap from a JSON file.
---@return nil
function M.Mindmap:load()
	local json_context = {}
	local json, _ = io.open(self.json_path, "r")
	if not json then
		-- Use save() to create a json file.
		self:save()
		self:log("[Mindmap] Mindmap not found at: " .. self.json_path .. ". Created a new one.", "info")
		return
	end
	json_context = vim.fn.json_decode(json:read("*a"))

	for _, table in pairs(json_context) do
		if type(table) == "table" then
			local mnode = M.Mindnode.from_table(table)
			self.mnode_table[mnode.timestamp] = mnode
		end
	end

	self:log("[Mindmap] Mindmap loaded at: " .. self.json_path, "info")
	json:close()
end

---Call log method of the logger, or call fallback method.
---@param msg string Log message.
---@param msg_level string Log message level.
---@return nil
function M.Mindmap:log(msg, msg_level)
	if self.logger then
		self.logger:log(msg, msg_level) -- Use __call?
	else
		local formatted_timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())
		msg = formatted_timestamp .. " " .. string.upper(msg_level) .. " " .. msg .. "\n"
		if package.loaded["vim.api"] then
			vim.api.nvim_out_write(msg)
		else
			print(msg)
		end
	end
end

----------
-- Class Method
----------

---Trigger a function on given mindnodes.
---@param mnodes table<string, Mindnode> Mindnodes to trigger the function on.
---@param func function|string Function to trigger.
---@param ... any Arguments for the function.
---@return any
function M.Mindmap.trigger(mnodes, func, ...)
	-- TODO: Return the output of the function (may be nil) as a table.
	-- TODO: If mindnodes is not given, then use self.mnode_table.
	-- TODO: Support for single mindnode.
	-- TODO: Add type checking.
	local output = {}
	if type(func) == "string" then
		for _, mnode in pairs(mnodes) do
			if type(mnode[func]) == "function" then
				mnode[func](mnode, ...)
			else
				print("Method '" .. func .. "' does not exist for mindnode.\n")
			end
		end
	elseif type(func) == "function" then
		for _, mnode in pairs(mnodes) do
			func(mnode, ...)
		end
	else
		print("Invalid argument type for 'func'\n.")
	end
	return output
end

--------------------

return M
