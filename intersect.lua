
local Vec2      = require 'cpml' .vec2
local INTERSECT = require 'cpml' .intersect
local CONSTS    = require 'acl2d.constants'

local max = math.max
local min = math.min
local abs = math.abs

local intersect = {}

-- @point_aabb
-- point is vec2
-- aabb.min and aabb.max are vec2
function intersect.point_aabb(point, aabb)
  return point.x >= aabb.min.x and point.x <= aabb.max.x and
         point.y >= aabb.min.y and point.y <= aabb.max.y
end

-- @point_aabb
-- point is vec2
-- circ.pos is vec2
-- circ.radius is number
function intersect.point_circle(point, circ)
  return (point - circ.pos):len2() <= circ.radius^2
end

-- @aabb_aabb
-- a.min and b.min are vec2
-- a.max and b.max are vec2
function intersect.aabb_aabb(a, b)
  return a.min.x <= b.max.x and a.max.x >= b.min.x and
         a.min.y <= b.max.y and a.max.y >= b.min.y
end

-- @aabb_circle
-- aabb.min and aabb.max are vec2
-- circ.pos is vec2
-- circ.radius is number
function intersect.aabb_circle(aabb, circ)
  return (circ.pos - Vec2(max(aabb.min.x, min(circ.pos.x, aabb.max.x)),
                          max(aabb.min.y, min(circ.pos.y, aabb.max.y))
                     )
         ):len2() <= circ.radius^2
end

-- @circle_aabb
-- circ.pos is vec2
-- circ.radius is number
-- aabb.min and aabb.max are vec2
function intersect.circle_aabb(circ, aabb)
  return intersect.aabb_circle(aabb, circ)
end

-- @circle_circle
-- a.pos and b.pos are vec2
-- a.radius and b.radius are numbers
function intersect.circle_circle(a, b)
  return (a.pos - b.pos):len2() <= (a.radius + b.radius)^2
end


-- @transform_aabb_system
-- angle is rotation angle in radians
-- origin is new origin point for the new system (before rotation!)
local function transform_aabb_system(aabb, angle, origin)
  local new_min = (aabb.min - origin):rotate(angle)
  local new_max = (aabb.max - origin):rotate(angle)
  return {
    min = Vec2(min(new_min.x, new_max.x),
               min(new_min.y, new_max.y)),
    max = Vec2(max(new_min.x, new_max.x),
               max(new_min.y, new_max.y))
  }
end



-- @transform_circle_system
-- angle is rotation angle in radians
-- origin is new origin point for the new system (before rotation!)
local function transform_circle_system(circle, angle, origin)
  return {
    pos    = (circle.pos - origin):rotate(angle),
    radius = circle.radius
  }
end


-- @circle_triangle
-- circ.pos is vec2
-- circ.radius is number
-- triangle.type is char from CONSTS.TILES
-- triangle.corner is vec2
local opposite_corner = Vec2(1, 1)
local A = Vec2(1, 0)
local B = Vec2(0, 1)
local AB = B - A
function intersect.circle_triangle(circ, tri)
  local angle = CONSTS.ROTATIONS[tri.type]
  local new_circle = transform_circle_system(circ, angle, tri.corner)
  local corner = CONSTS.NULLVEC
  local C = new_circle.pos
  -- if center of circle is above the [x + y = 1] line, then act as aabb
  if C.x + C.y <= 1 then
    local tri_aabb = {min = corner, max = opposite_corner}
    return intersect.aabb_circle(tri_aabb, new_circle)
  end
  -- project C onto AB and get the distance of that projection to C
  local distvec = C - (A + AB * max(0, min(1, AB:dot(C-A) / AB:len2())))
  return distvec:len2() <= circ.radius * circ.radius
end

-- @aabb_triangle
-- aabb.min and aabb.max are vec2
-- triangle.type is char from CONSTS.TILES
-- triangle.corner is vec2
function intersect.aabb_triangle(aabb, tri)
  local angle = CONSTS.ROTATIONS[tri.type]
  local new_aabb = transform_aabb_system(aabb, angle, tri.corner)
  local corner = CONSTS.NULLVEC
  local new_max = new_aabb.max
  -- if bottom right corner is above the [x + y = 1] line, then act as aabb
  if new_max.x + new_max.y <= 1 then
    local tri_aabb = {min = corner, max = opposite_corner}
    return intersect.aabb_aabb(tri_aabb, new_aabb)
  end
  return new_aabb.min.x + new_aabb.min.y <= 1
end


return intersect

