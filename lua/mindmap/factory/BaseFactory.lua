--------------------
-- Class BaseFactory
--------------------

---@class BaseFactory
---@field base_cls table Base class of the factory. Registered classes should inherit from this class.
---@field registered_cls table<string, table> Table of registered classes.
local BaseFactory = {}
BaseFactory.__index = BaseFactory

---Create a new factory.
---@param base_cls table Base class of the factory. Registered classes should inherit from this class.
---@return BaseFactory factory The created factory.
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
---@param type_to_be_inherited? string Type of a registered class to be inherited. If not provided, use `self.base_cls` instead. Default: `nil`.
---@return boolean is_registered Whether the class is registered successfully.
function BaseFactory:register(type_to_be_registered, cls_to_be_registered, type_to_be_inherited)
	local cls_to_be_inherited = self:get_registered_class(type_to_be_inherited or "N/A") or self.base_cls

	if self.registered_cls[type_to_be_registered] then
		vim.notify(
			"[BaseFactory] Type `" .. type_to_be_registered .. "` already registered. Aborting registration.",
			vim.log.levels.WARN
		)
		return false
	end
	if not cls_to_be_inherited.new or type(cls_to_be_inherited.new) ~= "function" then
		vim.notify(
			"[BaseFactory] Class to be inherited does not have a `new` method. Aborting registration.",
			vim.log.levels.ERROR
		)
		return false
	end
	if not cls_to_be_registered.new or type(cls_to_be_registered.new) ~= "function" then
		vim.notify(
			"[BaseFactory] Class to be registered `"
				.. type_to_be_registered
				.. "` does not have a `new` method. Binding default `new` method.",
			vim.log.levels.WARN
		)

		function cls_to_be_registered:new(...)
			-- NOTE: The first parameter of the `new` method in the base class should be the type of the class.
			local ins = cls_to_be_inherited:new(type_to_be_registered, ...)
			ins.__index = ins
			setmetatable(ins, cls_to_be_registered)

			---@cast ins BaseFactory
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
---@return table? registered_class The registered class or nil if not found.
function BaseFactory:get_registered_class(registered_type)
	local registered_cls = self.registered_cls[registered_type]
	if not registered_cls then
		vim.notify(
			"[BaseFactory] Type `" .. registered_type .. "` is not registered. Aborting retrieval.",
			vim.log.levels.WARN
		)
		return
	end

	return registered_cls
end

---Get all registered types.
---@return string[] registered_types All registered types.
function BaseFactory:get_registered_types()
	local registered_types = {}
	for registered_type, _ in pairs(self.registered_cls) do
		table.insert(registered_types, registered_type)
	end

	return registered_types
end

---Create a registered class.
---@param registered_type string Registered type.
---@param ... any Additional arguments.
---@return table? created_class The created class or nil if creation fails.
function BaseFactory:create(registered_type, ...)
	local registered_cls = self:get_registered_class(registered_type)
	if not registered_cls then
		vim.notify(
			"[BaseFactory] Type `" .. registered_type .. "` is not registered. Aborting creation.",
			vim.log.levels.ERROR
		)
		return
	end

	return registered_cls:new(...)
end

--------------------

return BaseFactory
