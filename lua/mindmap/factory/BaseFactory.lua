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
---@param type_to_be_inherited? string Type of a registered class to be inherited. If not provided, use `self.base_cls` instead. Default: nil.
---@return boolean _ Whether the class is registered.
function BaseFactory:register(type_to_be_registered, cls_to_be_registered, type_to_be_inherited)
	local cls_to_be_inherited = self:get_registered_class(type_to_be_inherited or "") or self.base_cls

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
---@return table? _ The registered class.
function BaseFactory:get_registered_class(registered_type)
	local registered_cls = self.registered_cls[registered_type]
	if not registered_cls then
		vim.notify("Type `" .. registered_type .. "` is not registered. Aborte getting.", vim.log.levels.WARN)
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
---@param ... any Information to create the class.
---@return table? _ The created class.
function BaseFactory:create(registered_type, ...)
	local registered_cls = self:get_registered_class(registered_type)
	if not registered_cls then
		vim.notify("Type `" .. registered_type .. "` is not registered. Aborte creating.", vim.log.levels.ERROR)
		return
	end

	return registered_cls:new(...)
end

--------------------

return BaseFactory
