--------------------
-- Class BaseFactory
--------------------

---@class BaseFactory
---@field base_cls table Base class of the factory. Registered classes should inherit from this class.
---@field registered_cls table<string, table>
local BaseFactory = {}
BaseFactory.__index = BaseFactory

---Create a new BaseFactory.
---@param base_cls table Base class of the factory. Registered classes should inherit from this class.
---@return BaseFactory _ The created factory.
function BaseFactory:new(base_cls)
	local factory = {
		base_cls = base_cls,
		registered_cls = {},
	}
	factory.__index = factory
	setmetatable(factory, BaseFactory)

	return factory
end

---Register a class.
---@param type_to_be_registered string Type to be registered.
---@param cls_to_be_registered table Class to be registered.
---@param cls_to_be_inherited? table Class to be inherited. Default: `self.base_cls`.
---@return boolean _ Whether the class is registered.
function BaseFactory:register(type_to_be_registered, cls_to_be_registered, cls_to_be_inherited)
	cls_to_be_inherited = cls_to_be_inherited or self.base_cls

	if self.registered_cls[type_to_be_registered] then
		vim.notify(
			"Type `" .. type_to_be_registered .. "` already registered. Aborte registering.",
			vim.log.levels.WARN
		)
		return false
	end
	if not cls_to_be_inherited.new or type(cls_to_be_inherited.new) ~= "function" then
		vim.notify("Class to be inherited does not have a `new` method. Aborte registering.", vim.log.levels.ERROR)
		return false
	end
	if not cls_to_be_registered.new or type(cls_to_be_registered.new) ~= "function" then
		vim.notify(
			"Class `" .. type_to_be_registered .. "` does not have a `new` method. Bind a `new` method to the class.",
			vim.log.levels.WARN
		)

		function cls_to_be_registered:new(...)
			-- NOTE: The first parameter of the `new` method in the base class should be the type of the class.
			local ins = cls_to_be_inherited:new(type_to_be_registered, ...)
			ins.__index = ins
			setmetatable(ins, cls_to_be_registered)

			return ins
		end
	end

	cls_to_be_registered.__index = cls_to_be_registered
	setmetatable(cls_to_be_registered, cls_to_be_inherited)

	self.registered_cls[type_to_be_registered] = cls_to_be_registered
	return true
end

---Get a registered class.
---@param registered_type string Registered type.
---@return table? _ The registered class.
function BaseFactory:get_registered_class(registered_type)
	local registered_cls = self.registered_cls[registered_type]
	if not registered_cls then
		vim.notify("Type `" .. registered_type .. "` is not registered. Aborte getting.", vim.log.levels.ERROR)
		return
	end

	return registered_cls
end

---Get all registered types.
---@return string[] _ All registered types.
function BaseFactory:get_registered_types()
	local registered_types = {}
	for registered_type, _ in pairs(self.registered_cls) do
		table.insert(registered_types, registered_type)
	end

	return registered_types
end

---Create a registered class.
---@param registered_type string Registered type.
---@param ...? any Information to create the class.
---@return table? _ The created class.
function BaseFactory:create(registered_type, ...)
	local registered_cls = self:get_registered_class(registered_type)
	if not registered_cls then
		vim.notify("Type `" .. registered_type .. "` is not registered. Aborte creating.", vim.log.levels.ERROR)
		return
	end

	return registered_cls:new(...)
end

---Convert a instance to a table.
---@param ins table The instance to be converted.
---@return table _ The converted table.
function BaseFactory:to_table(ins)
	return {
		type = ins.type,
		id = ins.id,
		file_name = ins.file_name,
		rel_file_path = ins.rel_file_path,
		--
		data = ins.data,
		tag = ins.tag,
		state = ins.state,
		version = ins.version,
		created_at = ins.created_at,
		incoming_edge_ids = ins.incoming_edge_ids,
		outcoming_edge_ids = ins.outcoming_edge_ids,
	}
end

---Convert a table to a instance.
---@param registered_type string Which registered type the table should be converted to.
---@param tbl table The table to be converted.
---@return table? _ The converted instance.
function BaseFactory:from_table(registered_type, tbl)
	local registered_cls = self:get_registered_class(registered_type)
	if not registered_cls then
		vim.notify("Type `" .. registered_type .. "` is not registered. Aborte converting.", vim.log.levels.ERROR)
		return
	end

	return registered_cls:new(
		tbl.type,
		tbl.id,
		tbl.file_name,
		tbl.rel_file_path,
		--
		tbl.data,
		tbl.tag,
		tbl.state,
		tbl.version,
		tbl.created_at,
		tbl.incoming_edge_ids,
		tbl.outcoming_edge_ids
	)
end

--------------------

return BaseFactory
