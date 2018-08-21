
local Base = {}

local function instantiate(super, ...)
  local obj = setmetatable({}, super)
  super.__call = super.__call or instantiate
  obj.__index = obj
  super.init(obj, ...)
  return obj
end

function Base:init(...)
  -- abstract initializer
end

function Base:construct(...)
  -- abstract *manual* constructor
end

Base.__index = Base
Base.__call = instantiate

return setmetatable({}, Base)

