
local setmetatable = setmetatable
local getmetatable = getmetatable

local Base = {}
Base.__index = Base

function Base:__call(...)
  local obj = setmetatable({}, self)
  obj.__index = obj
  self.init(obj, ...)
  return obj
end

function Base:super()
  return getmetatable(self)
end

function Base:init(...)
  -- abstract initializer
end

return setmetatable({}, Base)

