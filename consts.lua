
return function(sx, sy)
  sy = sy or sx
  return {
    NOGROUP = 'none',
    REPEL = {24 * sx, 24 * sy},
    EPSILON = 2^-8,
    SHAPE_AABB = 1,
    SHAPE_CIRCLE = 2,
  }
end

