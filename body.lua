local min, max, sqrt = math.min, math.max, math.sqrt

local Consts = require 'acl2d.consts'
local Intersect = require 'acl2d.intersect'
local Base = require 'acl2d.base'
local Body = Base()

function Body:init(x, y, type, shape, group, inertia)
  self.type = type
  self.x = x
  self.y = y
  self.mx = 0
  self.my = 0
  self.shape = shape
  self.group = group
  self.inertia = sqrt(inertia or 0)
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
  return Intersect[self.type][body.type](
    { self.x, self.y, unpack(self.shape) },
    { body.x, body.y, unpack(body.shape) }
  )
end

function Body:update(dt)
  local dx, dy = self.mx * dt, self.my * dt
  self.x = self.x + dx
  self.y = self.y + dy
  self.mx = (self.mx - dx) * self.inertia
  self.my = (self.my - dy) * self.inertia
end

function Body:clamp(left, top, right, bottom)
  self.x = max(left, min(right - Consts.EPSILON, self.x))
  self.y = max(top, min(bottom - Consts.EPSILON, self.y))
end

function Body:move(dx, dy)
  self.mx = self.mx + dx
  self.my = self.my + dy
end

return Body

