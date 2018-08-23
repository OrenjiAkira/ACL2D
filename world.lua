local ceil = math.ceil

local Consts = require 'acl2d.consts'
local Base = require 'acl2d.base'
local Group = require 'acl2d.group'
local Body = require 'acl2d.body'
local World = Base()

local defaults = {
  region_size = 4,
}

-- width: max width of the world in arbitrary units
-- height: max height of the world in arbitrary units
-- (bodies will be clamped inside the world's dimensions!)
-- options:
-- + region_size: square side size of a region in arbitrary units
function World:init(width, height, options)
  assert(width and height, "Must receive 'width' & 'height' arguments!")
  local options = options or {}
  local region_size = options.region_size or defaults.region_size
  self.regions = {}
  self.width, self.height = width, height
  self.cols = ceil(width / region_size)
  self.rows = ceil(height / region_size)
  self.rsize = region_size

  -- generate regions
  for idx = 1, ceil(self.cols * self.rows) do
    self.regions[idx] = {
      [Consts.NOGROUP] = {}
    }
  end

  -- generate new group
  self.groups = {}
  self.bodies = {}
  self:newGroup(Consts.NOGROUP)
end

function World:getWidth() return self.width end
function World:getHeight() return self.height end
function World:getDimensions() return self.width, self.height end

function World:getGroup(name)
  return self.groups[name]
end

function World:newGroup(name, color)
  local group = Group(name, color)
  self.groups[name] = group
  return group
end

function World:newRectangularBody(x, y, w, h, groupname)
  groupname = groupname or Consts.NOGROUP
  local body = Body(x, y, Consts.SHAPE_AABB, {w/2, h/2}, self.groups[groupname])
  table.insert(self.bodies, body)
  print(("New AABB @ (%+.3f, %+.3f) in group '%s'"):format(x, y, groupname))
  return body
end

function World:newCircularBody(x, y, rad, groupname)
  groupname = groupname or Consts.NOGROUP
  local body = Body(x, y, Consts.SHAPE_CIRCLE, {rad}, self.groups[groupname])
  table.insert(self.bodies, body)
  print(("New Circle @ (%+.3f, %+.3f) in group '%s'"):format(x, y, groupname))
  return body
end

function World:update(dt)
  local bodies = self.bodies
  local body_count = #bodies
  for i = 1, body_count do
    local body = bodies[i]
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
    graphics.setColor(self.groups[body:getGroup()]:getColor())
    local x, y = body:getPosition()
    if body:getType() == Consts.SHAPE_AABB then
      local hw, hh = body.shape[1], body.shape[2]
      graphics.rectangle("line", x-hw, y-hh, hw+hw, hh+hh)
    elseif body:getType() == Consts.SHAPE_CIRCLE then
      local rad = body.shape[1]
      graphics.ellipse("line", x, y, rad, rad)
    end
  end
  graphics.pop()
end

return World

