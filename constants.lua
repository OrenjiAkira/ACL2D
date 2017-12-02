
local Vec2 = require 'cpml' .vec2

local CONSTS = {}

CONSTS.EPSILON = 1.19209290e-07
CONSTS.ELASTIC = .215
CONSTS.PRECISION = 3
CONSTS.MAXSPEED = 0.995
CONSTS.COLLISION_BUFFER = 2^12

CONSTS.SQRT_2 = math.sqrt(2)
CONSTS.AXIS = {
  Vec2( 0, -1),
  Vec2( 1,  0),
  Vec2( 0,  1),
  Vec2(-1,  0),
  Vec2(-1, -1) / CONSTS.SQRT_2,
  Vec2( 1, -1) / CONSTS.SQRT_2,
  Vec2( 1,  1) / CONSTS.SQRT_2,
  Vec2(-1,  1) / CONSTS.SQRT_2,
}

CONSTS.SHAPES = {
  ["circle"]    = 0,
  ["rectangle"] = 1,
}

CONSTS.TILE_FLOOR = '.'
CONSTS.TILE_WALL  = '#'
CONSTS.TILE_W_UL  = 'y'
CONSTS.TILE_W_UR  = 'u'
CONSTS.TILE_W_DR  = 'n'
CONSTS.TILE_W_DL  = 'b'

CONSTS.TILES = {
  [CONSTS.TILE_FLOOR] = true,
  [CONSTS.TILE_WALL ] = true,
  [CONSTS.TILE_W_UL ] = true,
  [CONSTS.TILE_W_UR ] = true,
  [CONSTS.TILE_W_DR ] = true,
  [CONSTS.TILE_W_DL ] = true,
}

local pi = math.pi
CONSTS.ROTATIONS = {
  [CONSTS.TILE_W_UL ] =  pi,
  [CONSTS.TILE_W_UR ] =  pi/2,
  [CONSTS.TILE_W_DR ] =  0,
  [CONSTS.TILE_W_DL ] = -pi/2,
}

CONSTS.CORNERS = {
  [CONSTS.TILE_W_UL ] =  Vec2(1, 1),
  [CONSTS.TILE_W_UR ] =  Vec2(0, 1),
  [CONSTS.TILE_W_DR ] =  Vec2(0, 0),
  [CONSTS.TILE_W_DL ] =  Vec2(1, 0),
}

CONSTS.NULLVEC = Vec2(0, 0)

return CONSTS

