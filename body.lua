local min, max = math.min, math.max

local Consts = require 'acl2d.consts'
local Intersect = require 'acl2d.intersect'
local Base = require 'acl2d.base'
local Body = Base()

function Body:init(x, y, type, shape, group)
  self.type = type
  self.x = x
  self.y = y
  self.mx = 0
  self.my = 0
  self.shape = shape
  self.group = group
end

function Body:getPosition() return self.x, self.y end

function Body:getType() return self.type end

function Body:setGroup(group)
  self.group = group
end

function Body:getGroup()
  return self.group:getName()
end

function Body:collidesWithGroup(groupname)
  return self.group:collidesWith(groupname)
end

function Body:getCollisionWith(body)
  if not self:collidesWithGroup(body:getGroup())
  or not body:collidesWithGroup(self:getGroup()) then
    return
  end
  return Intersect[self.type][body.type](
    { self.x, self.y, unpack(self.shape) },
    { body.x, body.y, unpack(body.shape) }
  )
end

function Body:update(world, dt)
  local left, right = 0, world:getWidth()
  local top, bottom = 0, world:getHeight()
  local dx, dy = self.mx * dt, self.my * dt
  self.x = min(right, max(left, self.x + dx))
  self.y = min(bottom, max(top, self.y + dy))
  self.mx, self.my = 0, 0
  -- NOTE: update region here
end

function Body:move(dx, dy)
  self.mx = self.mx + dx
  self.my = self.my + dy
end

return Body

