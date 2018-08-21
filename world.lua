local sqrt, max = math.sqrt, math.max

local Consts = require 'acl2d.consts'
local Base = require 'acl2d.base'
local Group = require 'acl2d.group'
local Body = require 'acl2d.body'
local World = Base()

function World:init()
  self.bodies = {}
  self.groups = {}
  self:newGroup(Consts.NOGROUP)
end

function World:newGroup(name)
  local group = Group(name)
  self.groups[name] = group
  return group
end

function World:newBody(x, y, w, h, groupname)
  groupname = groupname or Consts.NOGROUP
  local body = Body(x, y, w, h, self.groups[groupname])
  table.insert(self.bodies, body)
  print(("Create body @ (%+.3f, %+.3f) in group '%s'"):format(x, y, groupname))
  return body
end

function World:update(dt)
  local bodies = self.bodies
  local body_count = #bodies
  for i = 1, body_count do
    local body = bodies[i]
    local ax, ay = body:getPosition()
    local aw, ah = body:getDimensions()
    for j = 1 + 1, body_count do
      local another = bodies[j]
      local collision = body:getCollisionWith(another)
      if collision then
        local dx, dy = unpack(collision.repulsion)
        body:move(dx, dy)
        another:move(-dx, -dy)
      end
    end
    body:update(dt)
  end
end

function World:draw(scale)
  local graphics = love.graphics
  graphics.push()
  graphics.scale(scale)
  graphics.setLineWidth(2/scale)
  for _,body in ipairs(self.bodies) do
    local color = self.groups[body:getGroup()]:getColor()
    local x, y = body:getMin()
    local w, h = body:getDimensions()
    graphics.setColor(color)
    graphics.rectangle("line", x, y, w, h)
  end
  graphics.pop()
end

return World

