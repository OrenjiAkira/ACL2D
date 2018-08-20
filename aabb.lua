
local Shape = require 'acl2d.shape'
local AABB = Shape(Shape.AABB)

-- private methods
local getMin
local getMax

function AABB:init(w, h, ow, oh)
  self.w = w
  self.h = h
  self.ow = ow
  self.oh = oh
end

function AABB:intersects(another)

end

function getMin(self) end

function getMax(self) end

return AABB

