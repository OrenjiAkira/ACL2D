
local World = require 'acl2d.world'

local acl2d = {}

function acl2d.newWorld(...)
  return World(...)
end

return acl2d

