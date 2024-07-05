local logger = require("logger").register_plugin("mindmap"):register_source("Base.Factory")

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
    logger.warn({
      content = "register class skipped",
      cause = "class already registered",
      extra_info = { type = type_to_be_registered },
    })
    return
  end

  if not cls_to_be_inherited.new or type(cls_to_be_inherited.new) ~= "function" then
    logger.error({
      content = "register class aborted",
      cause = "inherited class missing 'new' method",
      extra_info = { type = type_to_be_inherited, cls_to_be_inherited = cls_to_be_inherited },
    })
    error("register class aborted")
  end

  if not cls_to_be_registered.new or type(cls_to_be_registered.new) ~= "function" then
    logger.error({
      content = "register class aborted",
      cause = "register class missing 'new' method",
      extra_info = { type = type_to_be_inherited, cls_to_be_inherited = cls_to_be_inherited },
    })
  end

  self.registered_cls[type_to_be_registered] = cls_to_be_registered
  logger.debug({
    content = "register class succeeded",
    extra_info = { registered_type = type_to_be_registered, registered_class = cls_to_be_registered },
  })
end

---Get a registered class. If `registered_type` is not provided, return `self.base_cls`.
---@param registered_type? string Registered type.
---@return table registered_class The registered class.
function BaseFactory:get_registered_class(registered_type)
  if not registered_type then
    return self.base_cls
  end

  local registered_cls = self.registered_cls[registered_type]
  if not registered_cls then
    logger.error({
      content = "get registered class failed",
      cause = "class not registered",
      extra_info = { type = registered_type, registered_types = self:get_registered_types() },
    })
    error("get registered class failed")
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
  local registered_class = self:get_registered_class(registered_type)

  -- The first argument of `new` method is the class type.
  -- In this way, we can use `create` method just like `new` method.
  local success, result = pcall(registered_class.new, registered_class, registered_type, ...)
  if not success then
    logger.error({
      content = "create registered class failed",
      cause = result,
      extra_info = { type = registered_type },
    })
    error("create registered class failed")
  end
  return result
end

--------------------

return BaseFactory
