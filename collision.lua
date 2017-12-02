
local Vec2  = require 'cpml' .vec2
local Queue = require 'acl2d.queue'

local INTERSECT = require 'acl2d.intersect'
local CONSTS    = require 'acl2d.constants'


-- @LOCAL_HELPER_VARS --

local random = (love or _G).math.random
local floor  = math.floor
local pi     = math.pi
local min    = math.min
local max    = math.max

local empty = {}
local low_corner = Vec2(1, 1)

local _circ_circ = INTERSECT['circle_circle']
local _aabb_circ = INTERSECT['aabb_circle']
local _circ_aabb = INTERSECT['circle_aabb']
local _aabb_aabb = INTERSECT['aabb_aabb']
local _circ_trig = INTERSECT['circle_triangle']
local _aabb_trig = INTERSECT['aabb_triangle']



-- @MODULE --

local collision = {}
local _collisions = Queue(CONSTS.COLLISION_BUFFER)



-- @LOCAL_BODY_VS_BODY_COLLISION_FUNCTIONS --

-- gets 'body vs body collision' check function
local function _getBodyChecker(a, b)
  return (a.is_circle    and b.is_circle   ) and _circ_circ or (
         (a.is_circle    and b.is_rectangle) and _circ_aabb or (
         (a.is_rectangle and b.is_circle   ) and _aabb_circ or _aabb_aabb))
end

-- packs a body's info ready for the intersection methods to use
local function _pack(body, future)
  local pos  = body.pos
  local move = body.movement
  local geom = body.geom
  local is_circle    = (body.shape == CONSTS.SHAPES.circle)
  local is_rectangle = (body.shape == CONSTS.SHAPES.rectangle)
  local half = Vec2(is_circle and geom.radius or geom.width /2,
                    is_circle and geom.radius or geom.height/2)
  return {
    solid        = body.solid,
    is_circle    = is_circle,
    is_rectangle = is_rectangle,
    movement     = move,
    pos          = future and pos + move or pos,
    min          = (future and pos + move or pos) - half,
    max          = (future and pos + move or pos) + half,
    radius       = geom.radius,
    half         = half,
  }
end

-- dealing with solid collision between bodies
local function _solidCollision(body, other)
  local repulsion = (body.pos - other.pos)
  local normal = repulsion:normalize()
  local distsqr = repulsion:len2()

  if distsqr <= CONSTS.EPSILON then
    normal = CONSTS.AXIS[random(#CONSTS.AXIS)]
    distsqr = CONSTS.MAXSPEED
  end

  if body.solid <= other.solid then
    body.movement = body.movement + normal * CONSTS.ELASTIC / distsqr
  end
  if other.solid <= body.solid then
    other.movement = other.movement - normal * CONSTS.ELASTIC / distsqr
  end
end



-- @LOCAL_BODY_VS_TILES_COLLISION_FUNCTIONS --

-- gets 'body vs tile collision' check function
-- a is body
-- b is tile
local function _getTileChecker(a, b)
  return (a.is_circle    and b.is_rectangle) and _circ_aabb or (
         (a.is_rectangle and b.is_rectangle) and _aabb_aabb or (
         (a.is_circle    and b.is_triangle ) and _circ_trig or _aabb_trig))
end

-- packs a tile's info ready for the intersection methods to use
local function _packTile(tile, i, j)
  local tile_pack = {}
  local tile_pos = Vec2(j, i)
  local is_rectangle = (tile == CONSTS.TILE_WALL)
  local is_triangle  = not is_rectangle
  local corner = is_triangle and (CONSTS.CORNERS[tile] + tile_pos)
  return {
    type = tile,
    is_rectangle = is_rectangle,
    is_triangle = is_triangle,
    corner = corner,
    min = tile_pos,
    max = tile_pos + low_corner,
    pos = tile_pos + low_corner/2,
  }
end

-- check if body collides with adjacent tiles
local function _checkTiles(body, tiles)
  local body_pack = _pack(body, true)

  for i = floor(body_pack.min.y), floor(body_pack.max.y) do
    for j = floor(body_pack.min.x), floor(body_pack.max.x) do
      local tile = (tiles[i] or empty)[j]
      if tile then
        local tile_pack = _packTile(tile, i, j)
        if _getTileChecker(body_pack, tile_pack)(body_pack, tile_pack) then
          return tile_pack
        end
      end
    end
  end

  return false
end

-- dealing with body slide movement along tiles
local function _slide(body, tiles)
  local v = body.movement
  local movements = { v }

  -- try 45 deg angles
  for i = -1, 1, 2 do
    local u = v:rotate(i*pi/4)
    table.insert(movements, u * u:dot(v) / u:len2())
  end

  -- try 80 deg angles
  for i = -1, 1, 2 do
    local u = v:rotate(i*4*pi/9)
    table.insert(movements, u * u:dot(v) / u:len2())
  end

  local moved
  for _,move in ipairs(movements) do
    moved = move
    body.movement = move
    if _checkTiles(body, tiles) then
      moved = CONSTS.NULLVEC
    else
      break
    end
  end

  return moved
end

local function _scooch(body, tiles)
  if not _checkTiles(body, tiles) then return CONSTS.NULLVEC end
  local pos = body.pos
  local movement = body.movement
  local moved = CONSTS.NULLVEC

  for n = 1, CONSTS.PRECISION do
    moved = moved + movement / 2^n
    body.movement = moved
    if _checkTiles(body, tiles) then
      moved = moved - movement / 2^n
    end
  end

  body.pos = pos + moved
  body.movement = movement - moved
  return moved
end



-- @MODULE_METHODS --

-- collide one body with all the others
-- O(n^2), unfortunately still very innefficient
function collision.resolveBodies(body, layers)
  local body_id = body.id
  local a = _pack(body, false)
  for _,lname in ipairs(body.masks) do
    for other_id, other in pairs(layers[lname]) do
      if body ~= other then
        local b = _pack(other, false)
        if _getBodyChecker(a, b)(a, b) then
          if body.solid > 0 and other.solid > 0 then
            _solidCollision(body, other)
          end
          _collisions:push({body.id, other_id})
        end
      end
    end
  end
end

-- collide one body with adjacent tiles
-- first we make the body move as much as possible (scooch)
-- then we try alternative directions (slide)
function collision.resolveTiles(body, tiles)
  if body.movement:is_zero() then return end
  local pos = body.pos
  local scooch_move = _scooch(body, tiles)
  local slide_move = _slide(body, tiles)
  body.pos = pos
  body.movement = scooch_move + slide_move
end

-- query collision queue
function collision.getNext()
  return not _collisions:isEmpty() and _collisions:pop()
end

-- clear collision queue
function collision.flush()
  _collisions:flush()
end

return collision

