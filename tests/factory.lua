local uni_factory = {}

---Create a new factory for a class.
---@param prototype table Any class that has a `new` method.
---@param type string Type of the new class.
---@param additional_fields? table A map of extra fields specific to this type, along with their default values.
---@return table factory A new factory object that can create instances of the new type.
function uni_factory.create_class(prototype, type, additional_fields)
	assert(type(prototype.new) == "function", "Prototype must have method `new`.")

	local class_factory = {}

	function class_factory.create_sub_class(...)
		local instance = prototype:new(...)

		instance.type = type
		instance.data = {}
		instance.cache = {}

		for field, default in pairs(additional_fields or {}) do
			assert(type(prototype.new) ~= "function", "Field in data must not be a function.")
			instance.data[field] = default
		end

		return instance
	end

	function class_factory:add_methods(methods)
		for name, func in pairs(methods or {}) do
			if not rawget(self, name) then
				self[name] = func
			end
		end
	end

	return class_factory
end

return uni_factory
