local strf = string.format
local min, max = math.min, math.max
local ceil, floor = math.ceil, math.floor

local Consts = require 'acl2d.consts'
local Base = require 'acl2d.base'
local Group = require 'acl2d.group'
local Body = require 'acl2d.body'
local World = Base()

setfenv(1, Consts)

local defaults = {
  region_size = 4,
}

local function getRegion(x, y, rsize, cols)
  local i, j = 1 + floor(y / rsize), 1 + floor(x / rsize)
  return j + (i - 1) * cols
end

local function addBodyToWorld(world, x, y, shapetype, shapeinfo, gname, inertia)
  x = max(0, min(world:getWidth() - EPSILON, x))
  y = max(0, min(world:getHeight() - EPSILON, y))
  gname = gname or NOGROUP
  assert(world:getGroup(gname), strf("No group '%s'", gname))
  local body = Body(x, y, shapetype, shapeinfo, gname, inertia)
  local idx = getRegion(x, y, world.rsize, world.cols)
  world.bodies[body] = true
  table.insert(world.regions[idx][gname], body)
  print(strf("New Body @ (%+.3f, %+.3f) in group '%s'", x, y, gname))
  return body
end

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
  for idx = 1, self.cols * self.rows do
    self.regions[idx] = {
      [NOGROUP] = {}
    }
  end

  -- generate new group
  self.bodies = {}
  self.groups = {}
  self:newGroup(NOGROUP)
end

function World:getWidth() return self.width end
function World:getHeight() return self.height end
function World:getDimensions() return self.width, self.height end

function World:getGroup(name)
  return self.groups[name]
end

function World:updateRegionDistribution()
  local regions, rsize, cols = self.regions, self.rsize, self.cols
  for idx, region in ipairs(regions) do
    for groupname, bodies in pairs(region) do
      local newsize = 0
      local oldsize = #bodies
      for n = 1, #bodies do
        local body = bodies[n]
        local x, y = body:getPosition()
        local newidx = getRegion(x, y, rsize, cols)
        if newidx == idx then
          newsize = newsize + 1
          bodies[newsize] = body
        else
          table.insert(regions[newidx][groupname], body)
        end
      end
      for n = oldsize, newsize + 1, -1 do
        bodies[n] = nil
      end
    end
  end
end

function World:newGroup(name, color)
  assert(type(name) == 'string',
         strf("Group name must be string (got '%s')", type(name)))
  assert(not self.groups[name], strf("Group '%s' already exists", name))
  local group = Group(name, color)
  self.groups[name] = group
  for idx = 1, self.cols * self.rows do
    self.regions[idx][name] = {}
  end
  return group
end

function World:newRectangularBody(x, y, w, h, groupname, inertia)
  return addBodyToWorld(self, x, y, SHAPE_AABB, {w/2, h/2}, groupname, inertia)
end

function World:newCircularBody(x, y, rad, groupname, inertia)
  return addBodyToWorld(self, x, y, SHAPE_CIRCLE, {rad}, groupname, inertia)
end

function World:removeBody(body)
  local x, y = body:getPosition()
  local idx = getRegion(x, y, self.rsize, self.cols)
  local bodies = self.regions[idx][body:getGroup()]
  local k = 0
  for i,another in ipairs(bodies) do
    if body == another then
      k = i
      break
    end
  end
  table.remove(bodies, k)
  self.bodies[body] = nil
end

function World:update(dt)
  local regions = self.regions
  local rsize, cols = self.rsize, self.cols
  for body in pairs(self.bodies) do
    local group = self.groups[body:getGroup()]
    local x, y = body:getPosition()
    local idx = getRegion(x, y, rsize, cols)
    local neighbours = {
      regions[idx - 1       ], -- left
      regions[idx           ], -- same
      regions[idx + 1       ], -- right
      regions[idx - 1 - cols], -- top-left
      regions[idx     - cols], -- top
      regions[idx + 1 - cols], -- top-right
      regions[idx + 1 + cols], -- bottom-left
      regions[idx     + cols], -- bottom
      regions[idx - 1 + cols], -- bottom-right
    }
    for k = 1, 9 do
      local region = neighbours[k]
      if region then
        for groupname in group:eachCollidingGroup() do
          for _,another in ipairs(region[groupname]) do
            if body ~= another then
              local collision = body:getCollisionWith(another)
              if collision then
                local dx, dy = unpack(collision.repulsion)
                body:move(dx, dy)
                another:move(-dx, -dy)
              end
            end
          end
        end
      end
    end
    body:update(dt)
    body:clamp(0, 0, self.width, self.height)
  end
  self:updateRegionDistribution()
end

function World:draw(scale)
  -- THIS IS FOR DEBUGGING ONLY.
  -- *NOT OPTIMISED DUE TO REPETITIVE DRAW CALLS*
  local graphics = love.graphics
  local rsize = self.rsize
  graphics.push()
  graphics.scale(scale)
  graphics.setLineWidth(2/scale)
  graphics.setColor(1, 1, 1)
  graphics.rectangle("line", 0, 0, self.width, self.height)
  for idx, region in ipairs(self.regions) do
    local i = 1 + floor(idx / self.cols)
    local j = (idx - 1) % self.cols + 1
    graphics.setColor(1, 1, 1, 0.5)
    graphics.rectangle("line", rsize * (j - 1), rsize * (i - 1), rsize, rsize)
    for groupname, bodies in pairs(region) do
      for _,body in ipairs(bodies) do
        graphics.setColor(self.groups[body:getGroup()]:getColor())
        local x, y = body:getPosition()
        if body:getType() == SHAPE_AABB then
          local hw, hh = body.shape[1], body.shape[2]
          graphics.rectangle("line", x-hw, y-hh, hw+hw, hh+hh)
        elseif body:getType() == SHAPE_CIRCLE then
          local rad = body.shape[1]
          graphics.ellipse("line", x, y, rad, rad)
        end
      end
    end
  end
  graphics.pop()
end

return World

