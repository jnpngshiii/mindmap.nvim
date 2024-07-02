local logger = require("mindmap.Logger"):register_source("Base.Factory")

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
---@return nil
function BaseFactory:register(type_to_be_registered, cls_to_be_registered, type_to_be_inherited)
  local cls_to_be_inherited = self:get_registered_class(type_to_be_inherited)

  if self.registered_cls[type_to_be_registered] then
    -- stylua: ignore
    logger.warn(
      "Register class skipped: "
        .. "class to be registered `" .. type_to_be_registered .. "` already registered."
    )
  end
  if not cls_to_be_inherited.new or type(cls_to_be_inherited.new) ~= "function" then
    -- stylua: ignore
    logger.error("Register class aborted: "
        .. "class to be inherited `" .. type_to_be_inherited .. "` does not have a `new` method.",
      { cls_to_be_inherited = cls_to_be_inherited }
    )
  end
  if not cls_to_be_registered.new or type(cls_to_be_registered.new) ~= "function" then
    -- stylua: ignore
    logger.warn(
      "Register class modified: "
        .. "class to be registered `" .. cls_to_be_registered .. "` does not have a `new` method, bind default `new` method instead."
    )

    function cls_to_be_registered:new(...)
      local ins = cls_to_be_inherited:new(...)
      ins.__index = ins
      setmetatable(ins, cls_to_be_registered)

      return ins
    end
  end
end

---Get a registered class. If not found, return `self.base_cls` instead.
---@param registered_type? string Registered type.
---@return table registered_class The registered class.
function BaseFactory:get_registered_class(registered_type)
  if not registered_type then
    return self.base_cls
  end

  local registered_cls = self.registered_cls[registered_type]
  if not registered_cls then
    -- stylua: ignore
    logger.warn(
      "Get registered class failed: "
        .. "class `" .. registered_type .. "` is not registered, return `self.base_cls` instead.")
    return self.base_cls
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
  local ok, result = pcall(self.get_registered_class, self, registered_type)
  if not ok then
    -- stylua: ignore
    logger.error(
      "Create instance failed: "
        .. "class `" .. registered_type .. "` is not registered.",
      { registered_types = self:get_registered_types() }
    )
    return
  end

  -- The first argument of `new` method is the class type.
  -- In this way, we can use `create` method just like `new` method.
  return result:new(registered_type, ...)
end

--------------------

return BaseFactory
