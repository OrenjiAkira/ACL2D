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
  local group = self.groups[groupname]
  local body = Body(x, y, w, h, group)
  body:setGroup(group)
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
    local agroup = body:getGroup()
    for j = 1 + 1, body_count do
      local another = bodies[j]
      local bgroup = another:getGroup()
      if agroup:collidesWith(bgroup:getName())
        or bgroup:collidesWith(agroup:getName()) then
        if body:isCollidingWith(another) then
          local bx, by = another:getPosition()
          local bw, bh = another:getDimensions()
          local sx, sy = Consts.REPEL*(aw + bw), Consts.REPEL*(ah + bh)
          local dx, dy = ax - bx, ay - by
          local dist2 = max(Consts.EPSILON, dx * dx + dy * dy)
          body:move(sx * dx / dist2, sy * dy / dist2)
          another:move(sx * -dx / dist2, sy * -dy / dist2)
        end
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
    local color = body:getGroup():getColor()
    local x, y = body:getMin()
    local w, h = body:getDimensions()
    graphics.setColor(color)
    graphics.rectangle("line", x, y, w, h)
  end
  graphics.pop()
end

return World

