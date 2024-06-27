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

local base_alg_version = 2
-- v0: Initial version.
-- v1: Rename to `BaseAlg`.
-- v2: Remove `data` field.

----------
-- Basic Method
----------

---Create a new algorithm.
---@param version? integer Version of the algorithm.
---@return BaseAlg base_alg The created algorithm.
function BaseAlg:new(version)
	local base_alg = {
		initial_ease = 250,
		initial_interval = 1,
		version = version or base_alg_version,
	}
	base_alg.__index = base_alg
	setmetatable(base_alg, BaseAlg)

	return base_alg
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
