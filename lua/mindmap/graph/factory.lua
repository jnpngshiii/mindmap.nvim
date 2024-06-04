---@alias cls_category string
---@alias cls_type string
---@alias cls table

---@class uni_factory
---@field cls_categories table<cls_category, table<cls_type, cls>>
local uni_factory = {
	cls_categories = {},
}

---Register a new class.
---@param cls_category string The category of the class.
---@param cls_prototype table The prototype of the class. Must have a `new` method and can have other base methods and fields.
function uni_factory.register_base(cls_category, cls_prototype)
	assert(type(cls_prototype.new) == "function", "Prototype must have a `new` method.")
	uni_factory.cls_categories[cls_category] = {
		prototype = cls_prototype,
	}
end

---Create a new class.
---@param cls_category string The category of the class.
---@param cls_type string The type of the class.
---@param additional_fields? table A map of additional fields to be added to the class.
---@param additional_methods? table A map of additional methods to be added to the class.
---@return cls sub_class A subclass of the prototype.
function uni_factory.create_class(cls_category, cls_type, additional_fields, additional_methods)
	assert(
		uni_factory.cls_categories[cls_category] and uni_factory.cls_categories[cls_category].prototype,
		"No prototype registered for class category `" .. cls_category .. "`."
	)

	-- Check if the class already exists.
	if uni_factory.cls_categories[cls_category][cls_type] then
		return uni_factory.cls_categories[cls_category][cls_type]
	end

	local prototype = uni_factory.cls_categories[cls_category].prototype
	local sub_class = setmetatable({}, { __index = prototype })

	function sub_class:new(...)
		local sub_class_instance = setmetatable(prototype:new(...), { __index = self })

		sub_class_instance.type = cls_type
		sub_class_instance.data = sub_class_instance.data or {}

		for field, default in pairs(additional_fields or {}) do
			assert(type(default) ~= "function", "Additional field `" .. field .. "` is a function.")
			-- assert(prototype[field] == nil, "Additional field `" .. field .. "` would override a prototype field.")
			sub_class_instance.data[field] = default
		end

		for name, func in pairs(additional_methods or {}) do
			assert(type(func) == "function", "Additional method `" .. name .. "` is not a function.")
			-- assert(prototype[name] == nil, "Additional method `" .. name .. "` would override a prototype method.")
			sub_class_instance[name] = func
		end

		return sub_class_instance
	end

	-- Register the new class.
	uni_factory.cls_categories[cls_category][cls_type] = sub_class

	return sub_class
end

---Add class methods to a class.
---@param cls_category string The category of the class.
---@param cls_type string The type of the class.
---@param cls_methods table<string, function> A map of class methods to be added to the class. The first argument of each function is the class itself.
function uni_factory.add_cls_method(cls_category, cls_type, cls_methods)
	assert(
		uni_factory.cls_categories[cls_category] and uni_factory.cls_categories[cls_category][cls_type],
		"No class type `" .. cls_type .. "` registered in class category `" .. cls_category .. "`."
	)

	for name, cls_method in pairs(cls_methods) do
		assert(type(cls_method) == "function", "Class method `" .. name .. "` is not a function.")

		-- Wrap the class method with the class instance.
		uni_factory.cls_categories[cls_category][cls_type][name] = function(...)
			return cls_method(uni_factory.cls_categories[cls_category][cls_type], ...)
		end
	end
end

--------------------

return uni_factory
