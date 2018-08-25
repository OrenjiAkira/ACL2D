
return setmetatable({
  NOGROUP = 'none',
  REPEL = 2e-5,
  EPSILON = 2^-8,
  ELASTICITY = 0.1,
  SHAPE_AABB = 1,
  SHAPE_CIRCLE = 2,
}, { __index = _G })

