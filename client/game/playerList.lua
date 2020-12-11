local colours = require "colours"
local players = {}
players.list = {}


players.init = function(self, nick)
  self.nick = nick
end


players.getSelf = function(self)
  return self.list[self.nick]
end


players.getTurn = function(self)
  return self.list[self.turn]
end

players.setList = function(self, newList)
  self.list = {}
  for i, nick in ipairs(newList) do
    self.list[#self.list + 1] = {nick = nick}
    self.list[nick] = self.list[#self.list]
  end
end


players.changeNick = function(self, oldNick, newNick)
  local p = self.list[oldNick]
  self.list[oldNick] = nil
  self.list[newNick] = p
  p.nick = newNick
  if self.nick == oldNick then
    self.nick = newNick
  end
end


players.join = function(self, nick)
  self.list[#self.list + 1] = {nick = nick}
  self.list[nick] = self.list[#self.list]
end


players.start = function(self, first, startTime)
  self.started = true
  self.turn = first
  for i, v in ipairs(self.list) do
    v.timeLeft = tonumber(startTime)
  end
end


players.lost = function(self, nick)
  local p = self.list[nick]
  p.lost = true
  p.timeLeft = 0
end


players.won = function(self, nick)
  self.winner = nick
end


players.next = function(self, turn, timeLeft)
  self.turn = turn
  print("Next", turn)
  self.list[turn].timeLeft = tonumber(timeLeft)
end


players.update = function(self, dt)
  if self.started and self.list[self.turn].timeLeft and not self.winner then
    self.list[self.turn].timeLeft = math.max(self.list[self.turn].timeLeft - dt, 0)
  end
end


players.draw = function(self)
  love.graphics.print("Players:", 8, 40)
  for i, v in ipairs(self.list) do
    if v.lost then
      love.graphics.setColor(colours.spectator)
    else
      love.graphics.setColor(colours.player)
    end
    love.graphics.print(v.nick, 16, 40 + i*16)
    if v.timeLeft then
      local time = string.format("%02d:%02d", v.timeLeft / 60, v.timeLeft % 60)
      love.graphics.print(time, 150, 40 + i*16)
    end
  end
end


return players