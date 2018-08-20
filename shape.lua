
local Base = require 'acl2d.base'
local Shape = Base()

-- Shape Types!
Shape.AABB = 0
Shape.POLYGON = 1

function Shape:init(type)
  self.type = type
end

function Shape:intersects(another)
  -- per type checking
  -- should return collision info:
  -- > colliding (boolean)
  -- > normal
end

return Shape

