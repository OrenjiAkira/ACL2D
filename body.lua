local sqrt, max = math.sqrt, math.max

local Consts = require 'acl2d.consts'
local Base = require 'acl2d.base'
local Body = Base()

function Body:init(x, y, w, h, group)
  self.x = x
  self.y = y
  self.hw = w/2
  self.hh = h/2
  self.mx = 0
  self.my = 0
  self.group = group
end

function Body:getPosition() return self.x, self.y end

function Body:getWidth() return self.hw*2 end

function Body:getHeight() return self.hh*2 end

function Body:getDimensions() return self.hw*2, self.hh*2 end

function Body:getMin() return self.x - self.hw, self.y - self.hh end

function Body:getMax() return self.x + self.hw, self.y + self.hh end

function Body:setGroup(group)
  self.group = group
end

function Body:getGroup()
  return self.group:getName()
end

function Body:collidesWithGroup(groupname)
  return self.group:collidesWith(groupname)
end

function Body:isCollidingWith(body)
  if not self:collidesWithGroup(body:getGroup())
  or not body:collidesWithGroup(self:getGroup()) then
    return false
  end
  local a0x, a0y = self.x - self.hw, self.y - self.hh
  local a1x, a1y = self.x + self.hw, self.y + self.hh
  local b0x, b0y = body:getMin()
  local b1x, b1y = body:getMax()
  return not (a0x > b1x or b0x > a1x or a0y > b1y or b0y > a1y)
end

function Body:getCollisionWith(body)
  if not self:isCollidingWith(body) then return end
  local sx = Consts.REPEL*(self.hw + self.hw + body:getWidth())
  local sy = Consts.REPEL*(self.hh + self.hh + body:getHeight())

  local x, y = body:getPosition()
  local dx, dy = self.x - x, self.y - y
  local dist2 = max(Consts.EPSILON, dx * dx + dy * dy)
  local dist = sqrt(dist2)
  return {
    repulsion = {
      sx * dx / dist / dist2,
      sy * dy / dist / dist2,
    }
  }
end

function Body:update(dt)
  local dx, dy = self.mx * dt, self.my * dt
  self.x, self.y = self.x + dx, self.y + dy
  self.mx, self.my = 0, 0
end

function Body:move(dx, dy)
  self.mx = self.mx + dx
  self.my = self.my + dy
end

return Body

