local misc = require("mindmap.misc")

local M = {}

---@alias Object table

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

---@param obj Object?
---@return Object
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
-- Class SimpleDatbase
--------------------

---@class SimpleDatbase
---@field item_table table<string, SimpleItem> Items in the database.
---@field add function Add a new item.
---@field remove function Remove an item.
---@field pop function Remove and return the last item.
---@field find function Find an item by ID.
M.SimpleDatbase = {
	item_table = {},
}

----------
-- Instance Method
----------

---@param obj Object?
---@return Object
function M.SimpleDatbase:new(obj)
	obj = obj or {}

	setmetatable(obj, self)
	self.__index = self

	return obj
end

function M.SimpleDatbase:add(item)
	self.item_table[item.id] = item
end

function M.SimpleDatbase:remove(id)
	self.item_table[id] = nil
end

----------
-- Class Method
----------

----------

return M
