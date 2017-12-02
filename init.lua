
local Vec2  = require 'cpml' .vec2

local CONSTS    = require 'acl2d.constants'
local COLLISION = require 'acl2d.collision'

-- physics module
local acl2d = {}

-- one needs first to load the map before using this physics module
-- load it with the acl2d.loadMap method
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
function acl2d.isMapLoaded()
  return not not _map,
         not _map and "Map not loaded, load it with `acl2d.loadMap()` first."
                  or nil
end

-- if you close the map, you lose all data
-- if you want to save it, you should do it elsewhere
function acl2d.closeMap()
  _map = nil
end

-- load map first before anything else
-- tiles is matrix of chars from CONSTS.TILES
function acl2d.loadMap(tiles, width, height)

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
    tiles  = tiles,
    width  = width,
    height = height,
    layers = {},
    ids    = {},
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
-- solid defines how collision will go down
-- if it's set to false or 0, it won't push back other bodies
-- if it's not set (nil), it defaults to 1
-- solid value zero means the body will be 'immaterial' and
-- will go through other bodies (it will still trigger collision);
-- solid values otherwise make bodies push each other, along with triggering
-- collisions. a bigger solid value will make other bodies with smaller
-- solid values be pushed back, but not vice-versa (higher values of solid
-- makes a body 'immovable' by smaller-solid-value bodies)

local _err_invalid_id = "Invlid ID type. Must be string."
local _err_taken_id = "ID already taken: %s"
local _err_invalid_solid = "Invalid value for 'solid' argument. Use number."
local _err_invalid_layer = "Invalid layer type. Must be string."
local _err_invalid_shape = "Invalid shape (not) specified: %s"
local _err_insufficient_geom = [=[
Insuficient geometry information!
Please provide either a radius or dimensions.]=]

function acl2d.loadBody(id, data, x, y)
  assert(acl2d.isMapLoaded())
  assert(type(id):match('string'), _err_invalid_id)
  assert(not _map.ids[id], _err_taken_id:format(id))
  assert(tonumber(data.solid or 1), _err_invalid_solid)
  assert(type(data.layer or 'L1'):match('string'), _err_invalid_layer)
  assert(CONSTS.SHAPES[data.shape], _err_invalid_shape:format(data.shape))
  assert((data.geom.width and data.geom.height)
         or data.geom.radius, _err_insufficient_geom)

  local solid = tonumber(data.solid or 1)
  local layer = data.layer
  local masks = data.masks or { layer }
  local shape = CONSTS.SHAPES[data.shape]
  local geomdata = data.geom
  local geom = {}
  geom.width  = geomdata.width  or geomdata.radius * 2
  geom.height = geomdata.height or geomdata.radius * 2
  geom.radius = geomdata.radius or (geomdata.width + geomdata.height) / 2
  x = x or -8000
  y = y or -8000

  -- mount body table
  local body =  {
    id       = id,
    pos      = Vec2(x, y),
    movement = CONSTS.NULLVEC,
    shape    = shape,
    geom     = geom,
    solid    = solid,
    layer    = layer,
    masks    = masks,
  }

  -- add body to map
  local layer_container = _map.layers[layer] or {}
  layer_container[id] = body
  _map.layers[layer] = layer_container

  -- return handle
  return body
end


-- get body by id
function acl2d.getBody(id, layer)
  assert(acl2d.isMapLoaded())
  if layer and _map.layers[layer] then return _map.layers[layer][id] end
  for lname, bodies in pairs(_map.layers) do
    if bodies[id] then return bodies[id] end
  end
end


-- remove body by id
function acl2d.removeBody(id, layer)
  assert(acl2d.isMapLoaded())
  assert(type(id):match('string'), "Invalid body id to remove.")
  if _map.layers[layer] then _map.layers[layer][id] = nil; return end
  for lname, bodies in pairs(_map.layers) do
    if bodies[id] then bodies[id] = nil; return end
  end
end


-- update method
-- you should call this and let things resolve themselves
-- before you do, it's important you setup the bodies' movement
function acl2d.update(dt)
  -- must have loaded map
  if not acl2d.isMapLoaded() then return end

  -- now we iterate bodies. It's O(n^2), not much you can do about it.
  for lname, layer in pairs(_map.layers) do
    for id, body in pairs(layer) do
      local pos = body.pos
      -- to move a body, you set its movement value
      -- don't multiply dt to it, let the physics handle it
      body.movement = body.movement * dt

      -- collision
      COLLISION.resolveBodies(body, _map.layers)
      if not body.movement:is_zero() then
        body.movement = _speedlimit(body.movement)
        COLLISION.resolveTiles(body, _map.tiles)
        body.pos = body.pos + body.movement
      end
    end
  end
end

-- flush all collisions
function acl2d.flush()
  COLLISION.flush()
end

-- get next collision
function acl2d.nextCollision()
  return COLLISION.getNext()
end

return acl2d

