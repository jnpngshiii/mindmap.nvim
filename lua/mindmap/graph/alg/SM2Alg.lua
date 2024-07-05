local logger = require("logger").register_plugin("mindmap"):register_source("Alg.SM2")

local BaseAlg = require("mindmap.base.BaseAlg")

--------------------
-- Class SM2Alg
--------------------

---@class SM2Alg : BaseAlg
local SM2Alg = {}
SM2Alg.__index = SM2Alg
setmetatable(SM2Alg, BaseAlg)

function SM2Alg:new(...)
  local ins = BaseAlg:new(...)
  setmetatable(ins, SM2Alg)

  return ins
end

--------------------

return SM2Alg
