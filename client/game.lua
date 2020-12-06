local game = {}

local gui = require "6raphicaluserinterface.src"()
local fonts = require "6raphicaluserinterface.src.utils".font

local players = {}
local gamestate = "lobby"
local chat = {}
local turn
local lastWord
local server
local words = {}
local nick

local errorStr, errorTimer = "", 0

local showError = function(str)
  errorStr = str
  errorTimer = 3
end

game.connect = function(self, nick, address, port)

  self.host = enet.host_create()
  local result, r1 = pcall(self.host.connect, self.host, address .. ":" .. port)
  if not result then
    return nil, r1
  end
  self.server = r1
  server = r1
  self.connectPending = nick
  return self.host
end

local chatSendButton = gui:add("button", 1000, 680, "send")
local chatTextbox    = gui:add("textLine", 200, 680, 790, chatSendButton, "message")
chatTextbox.validate = function(str) return str end

chatSendButton.callback = function(children)
  local msg = children.message.text
  if #msg == 0 then return end
  server:send("chat:" .. msg)
  children.message:clear()
end

local guessSendButton = gui:add("button", 1000, 320, "send")
local guessTextbox    = gui:add("textLine", 200, 320, 790, guessSendButton, "word")
guessTextbox.validate = function(str) return str end

guessSendButton.callback = function(children)
  local newWord = children.word.text
  if #newWord == 0 then return end
  if words[#words] then
    if not words[#words]:valid(newWord) then
      showError("This word doesn't work here!")
      return
    elseif words[newWord] then
      showError("This word was already played!")
      children.word:clear()
      return
    end
  end
  server:send("word:" .. newWord)
  children.word:clear()
end

local startButton = gui:add("button", 200, 16, "Start!")

startButton.callback = function()
  server:send("start")
end

game.update = function(self, dt)
  local ret = false
  while true do
    local event = self.host:service(0)
    if self.connectPending and self.server:state() == "connected" then
      print("Attempting connection")
      self.server:send("list")
      self.server:send("nick" .. ":" .. self.connectPending)
      nick = self.connectPending
      self.connectPending = false
    end

    if event and event.type == "receive" then
      ret = true

      local t, args = event.data:match("^([^%:]+)%:?(.*)")
      print("Received event of type", t, event.data)
      if t == "list" then
        players = {}
        for i, player in ipairs(args:split(":")) do
          players[#players + 1] = {nick = player}
          players[player] = players[#players]
        end
      elseif t == "nick" then
        local oldNick, newNick = args:match("([^%:]+)%:([^%:]+)")
        print(oldNick, newNick)
        local p = players[oldNick]
        players[oldNick] = nil
        players[newNick] = p
        p.nick = newNick
      elseif t == "join" then
        local nick = args:match("([^%:]+)%:")
        players[#players + 1] = {nick = nick}
        players[nick] = players[#players]
      elseif t == "start" then
        local startTime
        gamestate = "game"
        print(event.data, args)
        turn, startTime = args:match("^([^%:]+)%:(%d+)")
        for i, v in ipairs(players) do
          v.timeLeft = tonumber(startTime)
        end
        gui:remove(startButton)
      elseif t == "chat" then
        chat[#chat + 1] = {args:match("^([^%:]+):(.+)")}
      elseif t == "loss" then
        local nick = args:match("^([^%:]+)%:?(.+)")
        local p = players[nick]
        p.lost = true
        -- handle own loss
      elseif t == "next" then
        local newWord, playerNick, playerTimeLeft = args:match("^([^%:]*)%:([^%:]+)%:(%d+)%:")
        if #newWord > 0 then
          lastWord = newWord
        end
        words[#words + 1] = newWord
        turn = playerNick
        players[turn].timeLeft = tonumber(playerTimeLeft)
      elseif t == "victory" then
        -- handle victory
      end
    else
      break
    end
  end

  gui:update(dt)

  errorTimer = math.max(errorTimer - dt, 0)

  if gamestate == "game" then
    players[turn].timeLeft = players[turn].timeLeft - dt
  end

  return ret
end

game.draw = function(self)
  gui:draw()

  for i = #chat, math.max(1, #chat - 20), -1 do
    local message = chat[i]
    local str = ("%s: %s"):format(message[1], message[2])
    love.graphics.print(str, 200, 660 - (#chat - i)*16)
  end

  love.graphics.print("Players:", 8, 40)
  for i, v in ipairs(players) do
    if v.lost then
      love.graphics.setColor(1/2, 1/2, 1/2)
    else
      love.graphics.setColor(7/8, 7/8, 7/8)
    end
    love.graphics.print(v.nick, 16, 40 + i*16)
    if v.timeLeft then
      local time = string.format("%02d:%02d", v.timeLeft / 60, v.timeLeft % 60)
      love.graphics.print(time, 150, 40 + i*16)
    end
  end

  if gamestate == "game" then
    local p = players[nick]
    local time = string.format("%02d:%02d", p.timeLeft / 60, p.timeLeft % 60)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(fonts[24])
    love.graphics.print(time, 8, 8)
    love.graphics.setFont(oldFont)
  end

  love.graphics.print("Played words:", 1100, 32)
  for i, v in ipairs(words) do
    love.graphics.print(v, 1108, 32+i*16)
  end

  love.graphics.setColor(3/4, 0, 0, math.min(1, errorTimer))
  love.graphics.print(errorStr, 200, 340)
end

game.mousepressed = function(self, x, y, b)
  gui:mousepressed(x, y, b)
end

game.mousereleased = function(self, x, y, b)
  gui:mousereleased(x, y, b)
end


game.keypressed = function(self, k, kk)
  gui:keypressed(k, kk)
end


game.textinput = function(self, char)
  gui:textinput(char)
end

return game