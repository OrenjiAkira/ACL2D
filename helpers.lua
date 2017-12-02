
local CONSTS = require 'physics.constants'

local HELPERS = {}

local _e = CONSTS.EPSILON
local abs = math.abs

function HELPERS.gt(a, b)
  return a > b + _e
end
function HELPERS.lt(a, b)
  return a < b - _e
end
function HELPERS.eq(a, b)
  return abs(a - b) <= _e
end
function HELPERS.lt_eq(a, b)
  return HELPERS.lt(a, b) or HELPERS.eq(a, b)
end
function HELPERS.gt_eq(a, b)
  return HELPERS.gt(a, b) or HELPERS.eq(a, b)
end

function HELPERS.speedlimit(move)
  if move:len2() > CONSTS.MAXSPEED then
    return move:trim(CONSTS.MAXSPEED)
  end
  return move
end

return HELPERS

