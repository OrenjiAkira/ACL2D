
local Base = require 'acl2d.base'

local Body = Base()
Body.__index = Body

function Body:init(x, y, w, h)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.mx = 0
  self.my = 0
end

function Body:getPosition() return self.x, self.y end

function Body:getWidth() return self.w end

function Body:getHeight() return self.h end

function Body:getDimensions() return self.w, self.h end

function Body:getMin() return self.x, self.y end

function Body:getMax() return self.x + self.w, self.y + self.h end

function Body:isCollidingWith(another)
  local a0x, a0y = self.x, self.y
  local a1x, a1y = a0x + self.w, a0y + self.h
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

return setmetatable({}, Body)

