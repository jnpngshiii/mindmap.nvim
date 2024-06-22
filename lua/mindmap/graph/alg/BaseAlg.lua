--------------------
-- Class BaseAlg
--------------------

DAY_SECONDS = 86400
HOUR_SECONDS = 3600
MINUTE_SECONDS = 60

---@alias AlgType string

---@class BaseAlg
---@field initial_ease integer Initial ease of the algorithm.
---@field initial_interval integer Initial interval of the algorithm.
---@field data table Data of the algorithm.
---@field version integer Version of the algorithm.
local BaseAlg = {}
BaseAlg.__index = BaseAlg

local base_alg_version = 1
-- v0: Initial version.
-- v1: Rename to `BaseAlg`.

----------
-- Basic Method
----------

---Create a new algorithm.
---@param data? table Data of the algorithm.
---@param version? integer Version of the algorithm.
---@return BaseAlg _ The created algorithm.
function BaseAlg:new(data, version)
	local base_alg = {
		initial_ease = 250,
		initial_interval = 1,
		data = data or {},
		version = version or base_alg_version,
	}

	setmetatable(base_alg, self)
	self.__index = self

	return base_alg
end

---@abstract
---Answer the card with "easy".
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseAlg:answer_easy(...)
	error("[BaseAlg] Please implement function `answer_easy` in subclass.")
end

---@abstract
---Answer the card with "good".
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseAlg:answer_good(...)
	error("[BaseAlg] Please implement function `answer_good` in subclass.")
end

---@abstract
---Answer the card with "again".
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseAlg:answer_again(...)
	error("[BaseAlg] Please implement function `answer_again` in subclass.")
end

----------
-- Helper Method
----------

---Adjust the interval for 8 or more days.
---@param interval integer The interval.
---@param fuzz? integer The fuzz factor.
---@return integer The new interval.
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
