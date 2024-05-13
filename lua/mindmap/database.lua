local mindmap = require("mindmap.mindmap")

---@alias mindmap.Mindmap Mindmap

local M = {}

--------------------
-- Class Database
--------------------

---@class Database
---@field mindmap_table table<string, Mindmap> Mindmaps in the database.
M.Database = {
	mindmap_table = {},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Database:init(obj)
	obj = obj or {}
	obj.mindmap_table = obj.mindmap_table or self.mindmap_table

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Add an database to the database.
---@param mnode Database
---@return nil
function M.Database:add(mnode)
	self.mnode_table[mnode.mnode_id] = mnode
end

---Pop an database from the database.
---@param id string ID of the database to pop.
---@return Database|nil
function M.Database:pop(id)
	local poped_database = self.mnode_table[id]
	if poped_database == nil then
		vim.api.nvim_out_write("No database found. Nothing to pop.\n")
		return nil
	end

	-- vim.api.nvim_out_write("Pop an database from database.\n")
	self.mnode_table[id] = nil
	return poped_database
end

---Remove an database from the database.
---@param index number
---@return nil
function M.Database:remove(index)
	local remove_database = self.mnode_table[index]
	if remove_database == nil then
		vim.api.nvim_out_write("No database found. Nothing to remove.\n")
	end

	-- vim.api.nvim_out_write("Remove an database from database.\n")
	self.mnode_table[index] = nil
end

---Find database(s) in the database.
---@param timestamp string|string[]
---@return Database|Database[]
function M.Database:find(timestamp)
	if type(timestamp) ~= "table" then
		if type(timestamp) == "string" then
			return self.mnode_table[timestamp]
		end
	end

	local found_databases = {}
	for _, v in pairs(timestamp) do
		found_databases[v] = self:find(v)
	end
	return found_databases
end

---Save the database to a JSON file.
---@return nil
function M.Database:save()
	local json_context = {}
	for _, mnode in pairs(self.mnode_table) do
		if mnode:check_health() then
			json_context[#json_context + 1] = mnode.to_table(mnode)
		else
			self:log("[Database] Invalid database (" .. mnode.mnode_id .. "), skip saving.", "error")
		end
	end
	json_context = vim.fn.json_encode(json_context)

	local json, err = io.open(self.json_path, "w")
	if not json then -- TODO:
		self:log("[Database] Could not save database at: " .. self.json_path, "error")
		error("Could not open file: " .. err)
	end

	json:write(json_context)
	json:close()
end

---Load the database from a JSON file.
---@return nil
function M.Database:load()
	local json_context = {}
	local json, _ = io.open(self.json_path, "r")
	if not json then
		-- Use save() to create a json file.
		self:save()
		self:log("[Database] Database not found at: " .. self.json_path .. ". Created a new one.", "info")
		return
	end
	json_context = vim.fn.json_decode(json:read("*a"))

	for _, table in pairs(json_context) do
		if type(table) == "table" then
			local mnode = M.Database.from_table(table)
			self.mnode_table[mnode.timestamp] = mnode
		end
	end

	self:log("[Database] Database loaded at: " .. self.json_path, "info")
	json:close()
end

----------
-- Class Method
----------

--------------------

return M
