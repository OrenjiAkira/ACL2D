
local Vec2  = require 'cpml' .vec2

local CONSTS    = require 'ACL2D.constants'
local COLLISION = require 'ACL2D.collision'

-- physics module
local ACL2D = {}

-- one needs first to load the map before using this physics module
-- load it with the ACL2D.loadMap method
local _map

-- speedlimit
local function _speedlimit(move)
  if move:len2() > CONSTS.MAXSPEED * CONSTS.MAXSPEED then
    return move:trim(CONSTS.MAXSPEED)
  end
  return move
end


-- check if map is loaded
-- returns true or false
-- if it's false it returns the error msg as the second value
function ACL2D.isMapLoaded()
  return not not _map,
         not _map and "Map not loaded, load it with `ACL2D.loadMap()` first."
                  or nil
end

-- if you close the map, you lose all data
-- if you want to save it, you should do it elsewhere
function ACL2D.closeMap()
  _map = nil
end

-- load map first before anything else
-- tiles is matrix of chars from CONSTS.TILES
function ACL2D.loadMap(tiles, width, height)

  -- check tiles
  for i = 1, height do
    assert(tiles[i], ("Invalid tilemap row index given (%d)"):format(i))
    for j = 1, width do
      local tile = tiles[i][j]
      assert(tile, ("Invalid tilemap col index given (%d)"):format(j))
      assert(CONSTS.TILES[tile],
             ("Invalid tile type at [%d, %d]: `%s`."):format(i, j, tile))
      if tile == CONSTS.TILE_FLOOR then tile = false end
      tiles[i][j] = tile
    end
  end

  _map = {
    tiles = tiles,
    width = width,
    height = height,
    bodies = {},
  }

  -- returns map because, may you want to draw its geometry?
  return _map
end


-- id is a unique string identificator for the body
-- x and y are numbers representing the position of the body
-- shape is a string enum (can be 'circle' or 'rectangle')
-- geom is shape info:
--   > if it's `circle`, it has `geom.radius` (number)
--   > if it's `rectangle`, it has `geom.width` and `geom.height` (numbers)
--     (note: x, y refer to the center of the geom)
function ACL2D.loadBody(id, x, y, shape, geom, solid)
  assert(ACL2D.isMapLoaded())
  assert(type(id):match('string'), "Invlid ID type. Must be string.")
  assert(not _map.bodies[id], ("ID already taken: %s"):format(id))

  -- solid defines how collision will go down
  -- if it's set to false or 0, it won't push back other bodies
  -- if it's not set (nil), it defaults to 1
  -- solid value zero means the body will be 'immaterial' and
  -- will go through other bodies (it will still trigger collision);
  -- solid values otherwise make bodies push each other, along with triggering
  -- collisions. a bigger solid value will make other bodies with smaller
  -- solid values be pushed back, but not vice-versa (higher values of solid
  -- makes a body 'immovable' by smaller-solid-value bodies)
  solid = (solid == false and 0) or (solid or 1)
  assert(type(solid):match('number') and solid >= 0,
         "Invalid value for 'solid' argument. Use false or positive number."
  )

  assert((geom.width and geom.height) or geom.radius,
         "Insuficient geometry information! \n" ..
         "Please provide either a radius or dimensions")
  geom.width  = geom.width  or geom.radius * 2
  geom.height = geom.height or geom.radius * 2
  geom.radius = geom.radius or (geom.width + geom.height) / 2

  -- mount body table
  local body =  {
    id         = id,
    pos        = Vec2(x, y),
    movement   = Vec2(0, 0),
    shape      = CONSTS.SHAPES[shape],
    geom       = geom,
    solid      = solid,
  }

  -- add body to map
  _map.bodies[id] = body

  -- return handle
  return body
end


-- get body by id
function ACL2D.getBody(id)
  assert(ACL2D.isMapLoaded())
  return _map.bodies[id]
end


-- remove body by id
function ACL2D.removeBody(id)
  assert(ACL2D.isMapLoaded())
  assert(type(id):match('string'), "Invalid body id to remove.")
  _map.bodies[id] = nil
end


-- iterate through bodies (to deal with collision?)
function ACL2D.iterateBodies()
  assert(ACL2D.isMapLoaded())
  return pairs(_map.bodies)
end

-- update method
-- you should call this and let things resolve themselves
-- before you do, it's important you setup the bodies' movement
function ACL2D.update(dt)
  -- must have loaded map
  if not ACL2D.isMapLoaded() then return end

  -- now we iterate bodies. It's O(n^2), not much you can do about it.
  for id,body in pairs(_map.bodies) do
    local pos = body.pos
    -- to move a body, you set its movement value
    -- don't multiply dt to it, let the physics handle it
    body.movement = body.movement * dt

    -- collision
    COLLISION.resolveBodies(body, _map.bodies)
    if not body.movement:is_zero() then
      body.movement = _speedlimit(body.movement)
      COLLISION.resolveTiles(body, _map.tiles)
      body.pos = body.pos + body.movement
    end
  end
end

-- flush all collisions
function ACL2D.flush()
  COLLISION.flush()
end

-- get next collision
function ACL2D.nextCollision()
  return COLLISION.getNext()
end

return ACL2D

