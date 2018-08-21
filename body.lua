
local Base = require 'acl2d.base'
local Body = Base()

function Body:init(x, y, w, h)
  self.x = x
  self.y = y
  self.hw = w/2
  self.hh = h/2
  self.mx = 0
  self.my = 0
  self.group = nil
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

function Body:collidesWithGroup(another)
  return self.group:collidesWith(another)
end

function Body:isCollidingWith(another)
  if not self:collidesWithGroup(another:getGroup())
  or not another:collidesWithGroup(self:getGroup()) then
    return false
  end
  local a0x, a0y = self.x - self.hw, self.y - self.hh
  local a1x, a1y = self.x + self.hw, self.y + self.hh
  local b0x, b0y = another:getMin()
  local b1x, b1y = another:getMax()
  return not (a0x > b1x or b0x > a1x or a0y > b1y or b0y > a1y)
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

