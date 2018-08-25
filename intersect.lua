local sqrt, max, min, abs = math.sqrt, math.max, math.min, math.abs
local unpack = unpack

local Consts = require 'acl2d.consts'

local function aabb_aabb(a, b)
  local ax, ay, ahw, ahh = unpack(a)
  local bx, by, bhw, bhh = unpack(b)

  local dx = abs(ax - bx) - (ahw + bhw)
  local dy = abs(ay - by) - (ahh + bhh)

  if dx > 0 or dy > 0 then return end

  local dist = max(Consts.EPSILON, Consts.ELASTICITY - min(abs(dx), abs(dy)))
  local repulsion = Consts.REPEL/(dist*dist)

  local sx = ahw + bhw
  local sy = ahh + bhh

  local vx, vy = ax - bx, ay - by
  local vlen = (vx*vx + vy*vy) / sqrt(max(Consts.EPSILON, vx*vx + vy*vy))

  return {
    repulsion = {
      sx*vx * repulsion / vlen,
      sy*vy * repulsion / vlen,
    }
  }
end

local function aabb_circle(a, c)
  local ax, ay, ahw, ahh = unpack(a)
  local cx, cy, rad = unpack(c)
  local acx = min(max(cx, ax - ahw), ax + ahw)
  local acy = min(max(cy, ay - ahh), ay + ahh)

  local dx = acx - cx
  local dy = acy - cy
  local dist2 = max(Consts.EPSILON, dx * dx + dy * dy)

  if dist2 > rad*rad then return end

  local sx = ahw + rad
  local sy = ahh + rad

  local vlen = sqrt(dist2)
  local dist = max(Consts.EPSILON, Consts.ELASTICITY - (rad - vlen))
  local repulsion = Consts.REPEL/(dist*dist)

  return {
    repulsion = {
      sx * dx * repulsion / vlen,
      sy * dy * repulsion / vlen,
    }
  }
end

local function circle_aabb(c, a)
  local collision = aabb_circle(a, c)
  if collision then
    local repulsion = collision.repulsion
    repulsion[1], repulsion[2] = -repulsion[1], -repulsion[2]
  end
  return collision
end

local function circle_circle(c1, c2)
  local c1x, c1y, rad1 = unpack(c1)
  local c2x, c2y, rad2 = unpack(c2)
  local dx = c1x - c2x
  local dy = c1y - c2y
  local dist2 = max(Consts.EPSILON, dx * dx + dy * dy)

  if dist2 > (rad1+rad2)*(rad1+rad2) then return end

  local scale = rad1 + rad2

  local vlen = sqrt(dist2)
  local dist = max(Consts.EPSILON, Consts.ELASTICITY - (rad1 + rad2 - vlen))
  local repulsion = Consts.REPEL/(dist*dist)

  return {
    repulsion = {
      dx * scale * repulsion / vlen,
      dy * scale * repulsion / vlen,
    }
  }
end

return {
  [Consts.SHAPE_AABB] = {
    [Consts.SHAPE_AABB] = aabb_aabb,
    [Consts.SHAPE_CIRCLE] = aabb_circle,
  },
  [Consts.SHAPE_CIRCLE] = {
    [Consts.SHAPE_AABB] = circle_aabb,
    [Consts.SHAPE_CIRCLE] = circle_circle,
  }
}

