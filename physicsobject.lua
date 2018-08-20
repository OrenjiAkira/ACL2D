
local Base = require 'acl2d.base'
local PhysicsObject = Base()

function PhysicsObject:init(world, id, x, y)
  self.world = world
  self.id = id
  self.x = x
  self.y = y
  self.components = {}
end

function PhysicsObject:update(dt)
end

return PhysicsObject

