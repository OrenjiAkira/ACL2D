local unpack, sqrt, max = unpack, math.sqrt, math.max

local Consts = require 'acl2d.consts'

local function aabb_aabb(a, b)
  local ax, ay, ahw, ahh = unpack(a)
  local bx, by, bhw, bhh = unpack(b)
  local a0x, a0y = ax - ahw, ay - ahh
  local a1x, a1y = ax + ahw, ay + ahh
  local b0x, b0y = bx - bhw, by - bhh
  local b1x, b1y = bx + bhw, by + bhh

  -- if not colliding return nil
  if not (a0x > b1x or b0x > a1x or a0y > b1y or b0y > a1y) then return end

  local sx = Consts.REPEL*(ahw+ahw+bhw+bhw)
  local sy = Consts.REPEL*(ahh+ahh+bhh+bhh)

  local dx, dy = ax - bx, ay - by
  local dist2 = max(Consts.EPSILON, dx * dx + dy * dy)
  local dist = sqrt(dist2)
  return {
    repulsion = {
      sx * dx / dist / dist2,
      sy * dy / dist / dist2,
    }
  }
end

local function aabb_circle(a, c)
end

local function circle_aabb(c, a)
  return aabb_circle(a, c)
end

local function circle_circle(c1, c2)
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

