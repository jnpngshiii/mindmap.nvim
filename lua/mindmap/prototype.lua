local misc = require("mindmap.misc")

local M = {}

--------------------
-- Class SimpleItem
--------------------

---@class SimpleItem
---@field id string Id of the item.
---@field type string Type of the item.
---@field created_at integer Created time of the item.
---@field updated_at integer Updated time of the item.
M.SimpleItem = {
	id = "",
	type = "",
	created_at = -1,
	updated_at = -1,
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.SimpleItem:new(obj)
	obj = obj or {}

	obj.id = obj.id or ("simpleitem-" .. misc.get_unique_id())
	obj.type = obj.type or "simpleitem"
	obj.created_at = obj.created_at or tonumber(os.time())
	obj.updated_at = obj.updated_at or tonumber(os.time())

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---@deprecated
---Check if the item is healthy.
---@return boolean
function M.SimpleItem:is_healthy()
	error("Not implemented")
end

---@deprecated
---This is a test function.
function M.SimpleItem:show_id()
	if vim.api then
		vim.api.nvim_out_write(self.id .. "\n")
	else
		print(self.id)
	end
end

----------
-- Class Method
----------

--------------------
-- Class SimpleDatabase
--------------------

-- SimpleDatabase is a simple database that stores items.
-- It is uesd in SimpleItem as a field in this repository.
--
-- Example:
-- ---@class Card : SimpleItem
--
-- ---@class Excerpt : SimpleItem
--
-- ---@class Mindnode : SimpleItem
-- ---@field cards SimpleDatabase Cards in the mindnode.
-- ---@field excerpts SimpleDatabase Excerpts in the mindnode.
--
-- ---@class Mindmap : SimpleItem
-- ---@field mindnodes SimpleDatabase Mindnodes in the mindmap.
--
-- ---@class Database : SimpleDatabase
-- ---@field mindmaps SimpleDatabase Mindmaps in the database.
--
-- NOTE: For convenience, the ID of a SimpleDatabase should be the same as the ID of the SimpleItem in which it belongs.
-- TODO: Maybe a better way to implement this?

---@class SimpleDatabase : SimpleItem
---@field db_path string Path to load and save the database. Default: {current_project_path}/{id}.json
---@field items table<string, SimpleItem> Items in the database.
M.SimpleDatabase = M.SimpleItem:new({
	db_path = "",
	items = {},
})

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.SimpleDatabase:new(obj)
	obj = obj or {}

	obj.db_path = obj.db_path or misc.get_current_proj_path()
	vim.fn.system("mkdir -p " .. obj.db_path)

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Add an item to the database.
---Key is the ID of the item.
---@param item SimpleItem Item to be added.
---@return nil
function M.SimpleDatabase:add(item)
	self.items[item.id] = item
end

---Remove an item from the database.
---@param id string Item ID to be removed.
---@return nil
function M.SimpleDatabase:remove(id)
	self.items[id] = nil
end

---@deprecated
---Pop an item from the database and return it.
---@param id string Item ID to be popped.
---@return SimpleItem|nil
function M.SimpleDatabase:pop(id)
	error("Not implemented")
end

---Find an item from the database.
---If the item is not found and created_if_not_found = true,
---then create and return a new item.
---@param id string Item ID to be found.
---@param created_if_not_found boolean Create a new item if not found.
---@return SimpleItem
function M.SimpleDatabase:find(id, created_if_not_found)
	local found_item = self.items[id]
	if not found_item and created_if_not_found then
		found_item = self:new({ id = id })
		print(found_item.type)
		self:add(found_item)
	end
	return found_item
end

---@deprecated
---@overload M.SimpleItem:is_healthy(): boolean
---Check if the database is healthy.
---@return boolean
function M.SimpleDatabase:is_healthy()
	error("Not implemented")
end

---Trigger a function on each item in the database.
---@param func function|string Function to trigger.
---If string, the function should be a method of the item. If function,
---the function should be a function that takes an item as the first argument.
---@param ... any Arguments for the function.
---@return any
function M.SimpleDatabase:trigger(func, ...)
	-- TODO: Return the output of the function (may be nil) as a table.
	local output = {}
	if type(func) == "string" then
		for _, item in pairs(self.items) do
			if type(item[func]) == "function" then
				item[func](item, ...)
			else
				print("Method '" .. func .. "' does not exist for item.\n")
			end
		end
	elseif type(func) == "function" then
		for _, item in pairs(self.items) do
			func(item, ...)
		end
	else
		print("Invalid argument type for 'func'\n.")
	end
	return output
end

-- TODO: Maybe save / load the whole database as a JSON file?

---Save the fields of items in the database to a JSON file.
---@return nil
function M.SimpleDatabase:save()
	local json_content = vim.fn.json_encode(misc.remove_table_field(self.items))

	local json_path = self.db_path .. "/" .. self.id .. ".json"
	local json, err = io.open(json_path, "w")
	if not json then
		error("Could not open file: " .. err)
	end

	json:write(json_content)
	json:close()
end

---Load the fields of items in the database from a JSON file.
---@return nil
function M.SimpleDatabase:load()
	local json_path = self.db_path .. "/" .. self.id .. ".json"
	local json, err = io.open(json_path, "r")
	if not json then
		return
		-- error("Could not open file: " .. err)
	end

	local json_content = vim.fn.json_decode(json:read("*a"))

	if type(json_content) == "table" then
		for k, v in pairs(json_content) do
			self.items[k] = self:new(v)
		end
	end
end

----------
-- Class Method
----------

----------

return M
