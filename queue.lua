
local Queue = {}
local queue_mt = { __index = Queue }

local _err_overflow = "Queue overflow, can't push!"
local _err_empty = "Queue empty, can't pop!"

function Queue:push(item, ...)
  if not item then return end
  assert(not self:isFull(), _err_overflow)
  self.buffer[self.tail] = item
  self.tail = self.tail % self.max + 1
  self.size = self.size + 1
  return self:push(...)
end

function Queue:pop(n)
  if n == 0 then return end
  assert(not self:isEmpty(), _err_empty)
  local item = self.buffer[self.head]
  self.buffer[self.head] = false
  self.head = self.head % self.max + 1
  self.size = self.size - 1
  return item, self:pop(n-1)
end

function Queue:flush()
  return self:pop(self.size)
end

function Queue:peak()
  return self.buffer[self.head]
end

function Queue:isEmpty()
  return self.size == 0
end

function Queue:isFull()
  return self.size >= self.max
end

return function(max)
  return setmetatable(
    {
      max = max,
      size = 0,
      head = 1,
      tail = 1,
      buffer = {},
    },
    queue_mt
  )
end

