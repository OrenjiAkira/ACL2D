local sqrt, max, min, abs = math.sqrt, math.max, math.min, math.abs
local unpack = unpack

local Base = require 'acl2d.base'
local Intersect = Base()

local aabb_aabb
local aabb_circle
local circle_aabb
local circle_circle

function Intersect:init(world)
  self.world = world
  self.consts = world.consts
  self.collisions = {
    [self.consts.SHAPE_AABB] = {
      [self.consts.SHAPE_AABB] = aabb_aabb,
      [self.consts.SHAPE_CIRCLE] = aabb_circle,
    },
    [self.consts.SHAPE_CIRCLE] = {
      [self.consts.SHAPE_AABB] = circle_aabb,
      [self.consts.SHAPE_CIRCLE] = circle_circle,
    },
  }
end

function Intersect:getCollision(type_a, type_b, a, b)
  return self.collisions[type_a][type_b](self.consts, a, b)
end

function aabb_aabb(consts, a, b)
  local ax, ay, ahw, ahh = unpack(a)
  local bx, by, bhw, bhh = unpack(b)
  local a0x, a0y = ax - ahw, ay - ahh
  local a1x, a1y = ax + ahw, ay + ahh
  local b0x, b0y = bx - bhw, by - bhh
  local b1x, b1y = bx + bhw, by + bhh

  -- if not colliding return nil
  if (a0x > b1x or b0x > a1x or a0y > b1y or b0y > a1y) then return end

  local sx = consts.REPEL*(ahw+ahw+bhw+bhw)
  local sy = consts.REPEL*(ahh+ahh+bhh+bhh)

  local dx, dy = ax - bx, ay - by
  local dist2 = max(consts.EPSILON, dx * dx + dy * dy)
  local dist = sqrt(dist2)
  return {
    repulsion = {
      sx * dx / dist / dist2,
      sy * dy / dist / dist2,
    }
  }
end

function aabb_circle(consts, a, c)
  local ax, ay, ahw, ahh = unpack(a)
  local cx, cy, rad = unpack(c)
  local acx = min(max(cx, ax - ahw), ax + ahw)
  local acy = min(max(cy, ay - ahh), ay + ahh)

  local dx = acx - cx
  local dy = acy - cy
  local dist2 = max(consts.EPSILON, dx * dx + dy * dy)

  if dist2 > rad*rad then return end

  dist2 = max(consts.EPSILON, (ax-cx) * (ax-cx) + (ay-cy) * (ay-cy))

  local sx = consts.REPEL*(ahw+ahw+rad+rad)
  local sy = consts.REPEL*(ahh+ahh+rad+rad)
  local dist = sqrt(dist2)
  return {
    repulsion = {
      sx * dx / dist / dist2,
      sy * dy / dist / dist2,
    }
  }
end

function circle_aabb(consts, c, a)
  local collision = aabb_circle(a, c)
  if collision then
    local repulsion = collision.repulsion
    repulsion[1], repulsion[2] = -repulsion[1], -repulsion[2]
  end
  return collision
end

function circle_circle(consts, c1, c2)
  local c1x, c1y, rad1 = unpack(c1)
  local c2x, c2y, rad2 = unpack(c2)
  local dx = c1x - c2x
  local dy = c1y - c2y
  local dist2 = max(consts.EPSILON, dx * dx + dy * dy)

  if dist2 > (rad1+rad2)*(rad1+rad2) then return end

  local sx = consts.REPEL*(rad1+rad1+rad2+rad2)
  local sy = sx
  local dist = sqrt(dist2)

  return {
    repulsion = {
      sx * dx / dist / dist2,
      sy * dy / dist / dist2,
    }
  }
end

return Intersect

