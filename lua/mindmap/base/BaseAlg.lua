--------------------
-- Class BaseAlg
--------------------

DAY_SECONDS = 86400
HOUR_SECONDS = 3600
MINUTE_SECONDS = 60

---@alias AlgType string

---@class BaseAlg
---@field initial_ease integer Initial ease factor of the algorithm. Default: `250`.
---@field initial_interval integer Initial interval of the algorithm in days. Default: `1`.
---@field version integer Version of the algorithm.
local BaseAlg = {}
BaseAlg.__index = BaseAlg

local base_alg_version = 3
-- v0: Initial version.
-- v1: Rename to `BaseAlg`.
-- v2: Remove `data` field.
-- v3: Add `check_health` method an `upgrade` method.

----------
-- Basic Method
----------

---Create a new algorithm.
---@param version? integer Version of the algorithm.
---@return BaseAlg? base_alg The created algorithm, or nil if check health failed.
function BaseAlg:new(version)
	local base_alg = {
		initial_ease = 250,
		initial_interval = 1,
		version = version or base_alg_version,
	}
	base_alg.__index = base_alg
	setmetatable(base_alg, BaseAlg)

	local success = base_alg:upgrade()
	if not success then
		vim.notify("[Base.Alg] Failed to upgrade alg. Return `nil`", vim.log.levels.WARN)
		return nil
	end

	if base_alg.check_health then
		local issues = base_alg:check_health()
		if #issues > 0 then
			vim.notify(
				"[Base.Alg] Health check failed: \n" .. table.concat(issues, "\n") .. "\nReturn `nil`.",
				vim.log.levels.WARN
			)
			return nil
		end
	end

	return base_alg
end

---Upgrade the alg to the latest version.
---To support version upgrades, implement functions named `upgrade_to_vX`
---where `X` is the version to upgrade to. Each function should only upgrade
---the alg by one version.
---Example:
---  ```lua
---  function BaseAlg:upgrade_to_v11(self)
---    self._new_field = "default_value"
---    return true
---  end
---  ```
---For multi-version upgrades (e.g., v8 to v11), this function will
---sequentially call the appropriate upgrade functions (v8 to v9,
---v9 to v10, v10 to v11) in order. If an intermediate upgrade
---function is missing, the version number will be forcibly updated
---without any changes to the alg's data.
---@return boolean success Whether the upgrade was successful.
function BaseAlg:upgrade()
	local current_version = self._version
	local latest_version = base_alg_version

	while current_version < latest_version do
		local next_version = current_version + 1
		local upgrade_func = self["upgrade_to_v" .. next_version]
		if upgrade_func then
			local success = upgrade_func(self)
			if not success then
				vim.notify("[Base.Alg] Failed to upgrade to `v" .. next_version .. ".`")
				return false
			end
		else
			vim.notify("[Base.Alg] Forced upgrade to `v" .. next_version .. ".`")
		end

		current_version = next_version
		self._version = current_version
	end

	return true
end

---Basic health check for alg.
---Subclasses should override this method.
---@return string[] issues List of issues. Empty if the alg is healthy.
function BaseAlg:check_health()
	local issues = {}

	if type(self.initial_ease) ~= "number" then
		table.insert(issues, "Invalid `initial_ease`: expected `number`, got `" .. type(self.initial_ease) .. "`;")
	end
	if type(self.initial_interval) ~= "number" then
		table.insert(issues, "Invalid `initial_ease`: expected `number`, got `" .. type(self.initial_interval) .. "`;")
	end

	return issues
end

---@abstract
---Answer the card with "easy".
---@param edge BaseEdge The edge being reviewed.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-local, unused-vararg
function BaseAlg:answer_easy(edge, ...)
	vim.notify("[Base] Method `answer_easy` is not implemented.", vim.log.levels.ERROR)
end

---@abstract
---Answer the card with "good".
---@param edge BaseEdge The edge being reviewed.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-local, unused-vararg
function BaseAlg:answer_good(edge, ...)
	vim.notify("[Base] Method `answer_good` is not implemented.", vim.log.levels.ERROR)
end

---@abstract
---Answer the card with "again".
---@param edge BaseEdge The edge being reviewed.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-local, unused-vararg
function BaseAlg:answer_again(edge, ...)
	vim.notify("[Base] Method `answer_again` is not implemented.", vim.log.levels.ERROR)
end

----------
-- Helper Method
----------

---Adjust the interval for 8 or more days with a random fuzz factor.
---See: "Anki also applies a small amount of random “fuzz” to prevent cards that
---  were introduced at the same time and given the same ratings from sticking
---  together and always coming up for review on the same day."
---@param interval integer The interval in days.
---@param fuzz? integer The fuzz factor. Default is 3.
---@return integer new_interval The new adjusted interval.
function BaseAlg:random_adjust_interval(interval, fuzz)
	fuzz = fuzz or 3

	if interval >= 8 then
		local choices = { -fuzz, 0, fuzz }
		local random_index = math.random(#choices)
		interval = interval + choices[random_index]
	end

	return interval
end

--------------------

return BaseAlg
