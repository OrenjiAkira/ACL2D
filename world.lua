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
  self.groups = {}
  self:newGroup(NOGROUP)
end

function World:getWidth() return self.width end
function World:getHeight() return self.height end
function World:getDimensions() return self.width, self.height end

function World:getGroup(name)
  return self.groups[name]
end

local function getDesiredRegion(x, y, rsize, cols)
  local i, j = 1 + floor(y / rsize), 1 + floor(x / rsize)
  return j + (i - 1) * cols
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
        local newidx = getDesiredRegion(x, y, rsize, cols)
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

function World:newRectangularBody(x, y, w, h, groupname)
  groupname = groupname or NOGROUP
  x = max(0, min(self.width - EPSILON, x))
  y = max(0, min(self.height - EPSILON, y))
  local body = Body(x, y, SHAPE_AABB, {w/2, h/2}, self.groups[groupname])
  local idx = getDesiredRegion(x, y, self.rsize, self.cols)
  table.insert(self.regions[idx][groupname], body)
  print(strf("New AABB @ (%+.3f, %+.3f) in group '%s'", x, y, groupname))
  return body
end

function World:newCircularBody(x, y, rad, groupname)
  groupname = groupname or NOGROUP
  x = max(0, min(self.width - EPSILON, x))
  y = max(0, min(self.height - EPSILON, y))
  local body = Body(x, y, SHAPE_CIRCLE, {rad}, self.groups[groupname])
  local idx = getDesiredRegion(x, y, self.rsize, self.cols)
  table.insert(self.regions[idx][groupname], body)
  print(strf("New Circle @ (%+.3f, %+.3f) in group '%s'", x, y, groupname))
  return body
end

function World:update(dt)
  local regions = self.regions
  local cols = self.cols
  for idx, region in ipairs(self.regions) do
    local neighbours = {
      regions[idx],
      regions[idx + 1],
      regions[idx + 1 - cols],
      regions[idx + cols],
      regions[idx + 1 + cols],
    }
    for groupname, bodies in pairs(region) do
      for _,body in ipairs(bodies) do
        for k = 1, 5 do
          local neighbour = neighbours[k]
          if neighbour then
            for _,another in ipairs(neighbour[groupname]) do
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
        body:update(dt)
        body:clamp(0, 0, self.width, self.height)
      end
    end
  end
  self:updateRegionDistribution()
end

function World:draw(scale)
  local graphics = love.graphics
  local rsize = self.rsize
  graphics.push()
  graphics.scale(scale)
  graphics.setLineWidth(2/scale)
  graphics.setColor(1, 1, 1, 1)
  graphics.rectangle("line", 0, 0, self.width, self.height)
  for idx, region in ipairs(self.regions) do
    local i = 1 + floor(idx / self.cols)
    local j = (idx - 1) % self.cols + 1
    graphics.setColor(1, 1, 1, 0.5)
    graphics.rectangle("line", rsize*(j - 1), rsize*(i - 1), rsize, rsize)
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

