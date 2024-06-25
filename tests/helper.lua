local mocks = {}

local function create_mock(name)
	mocks[name] = {}
	return setmetatable({}, {
		__index = function(_, key)
			if mocks[name][key] == nil then
				mocks[name][key] = function() end
			end
			return mocks[name][key]
		end,
		__newindex = function(_, key, value)
			mocks[name][key] = value
		end,
	})
end

package.loaded["nui"] = create_mock("nui")
package.loaded["nui"]["popup"] = create_mock("popup")

return mocks
