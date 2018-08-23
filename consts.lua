
return setmetatable({
  NOGROUP = 'none',
  REPEL = 24,
  EPSILON = 2^-8,
  SHAPE_AABB = 1,
  SHAPE_CIRCLE = 2,
}, { __index = _G })

