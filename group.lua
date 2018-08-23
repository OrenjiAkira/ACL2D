local random = love.math.random

local Consts = require 'acl2d.consts'
local Base = require 'acl2d.base'
local Group = Base()

function Group:init(name, color)
  self.name = name
  self.color = color or {
    .5+.5*random(),
    .5+.5*random(),
    .5+.5*random()
  }
  self.mask = {
    [Consts.NOGROUP] = true
  }
end

function Group:getName()
  return self.name
end

function Group:getColor()
  return self.color
end

function Group:setCollisionGroups(groups)
  for _,group in ipairs(groups) do
    self.mask[group] = true
  end
end

function Group:collidesWith(group)
  return self.mask[group]
end

function Group:eachCollidingGroup()
  return pairs(self.mask)
end

return Group

