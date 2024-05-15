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

	obj.id = "simpleitem-" .. misc.get_unique_id()
	obj.created_at = tonumber(os.time())
	obj.updated_at = tonumber(os.time())

	setmetatable(obj, self)
	self.__index = self

	return obj
end

----------
-- Class Method
----------

--------------------
-- Class SimpleDatabase
--------------------

---@class SimpleDatabase
---@field items table<string, SimpleItem> Items in the database.
M.SimpleDatabase = {
	items = {},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.SimpleDatabase:new(obj)
	obj = obj or {}

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
function M.SimpleDatabase:pop(id)
	error("Not implemented")
end

---@deprecated
---Find an item from the database.
---If the item is not found and created_if_not_found = true,
---then create and return a new item.
function M.SimpleDatabase:find(id, created_if_not_found)
	error("Not implemented")
end

---@deprecated
---Decorate each item in the database.
function M.SimpleDatabase:decorate()
	error("Not implemented")
end

----------
-- Class Method
----------

----------

return M
