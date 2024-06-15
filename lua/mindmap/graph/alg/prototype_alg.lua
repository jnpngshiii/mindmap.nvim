--------------------
-- Class PrototypeAlg
--------------------

---@alias AlgType string

---@class PrototypeAlg
---@field initial_ease integer Initial ease of the algorithm.
---@field initial_interval integer Initial interval of the algorithm.
---@field data table Data of the algorithm.
---@field version integer Version of the algorithm.
local PrototypeAlg = {}

local prototype_alg_version = 0
-- v0: Initial version.

---Create a new algorithm.
---@param data? table Data of the algorithm.
---@param version? integer Version of the algorithm.
---@return PrototypeAlg _ The created algorithm.
function PrototypeAlg:new(data, version)
	local prototype_alg = {
		initial_ease = 250,
		initial_interval = 1,
		data = data or {},
		version = version or prototype_alg_version,
	}

	setmetatable(prototype_alg, self)
	self.__index = self

	return prototype_alg
end

---@abstract
---Answer the card with "easy".
---@diagnostic disable-next-line: unused-vararg
function PrototypeAlg:answer_easy(...)
	error("[PrototypeAlg] Please implement function `answer_easy` in subclass.")
end

---@abstract
---Answer the card with "good".
---@diagnostic disable-next-line: unused-vararg
function PrototypeAlg:answer_good(...)
	error("[PrototypeAlg] Please implement function `answer_good` in subclass.")
end

---@abstract
---Answer the card with "good".
---@diagnostic disable-next-line: unused-vararg
function PrototypeAlg:answer_again(...)
	error("[PrototypeAlg] Please implement function `answer_again` in subclass.")
end

return PrototypeAlg
