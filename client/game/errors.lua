local colours = require "colours"
local errors = {}
errors.list = {}

errors.push = function(self, msg)
  table.insert(self.list, 1, {message = msg, timer = 3})
  for i = 5, #self.list do
    self.list[i] = nil
  end
end


errors.update = function(self, dt)
  for i, v in ipairs(self.list) do
    v.timer = math.max(v.timer - dt, 0)
  end
end


errors.draw = function(self)
  for i, v in ipairs(self.list) do
    love.graphics.setColor(colours.error(math.min(1, v.timer)))
    love.graphics.print(v.message, 200, 330 + i * 16)
  end
end


return errors