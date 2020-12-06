local game = {}

local gui = require "6raphicaluserinterface.src"()

local players = {}
local gamestate = "lobby"
local chat = {}
local turn
local lastWord
local server
local words = {}

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

local guessSendButton = gui:add("button", 1000, 340, "send")
local guessTextbox    = gui:add("textLine", 200, 340, 790, guessSendButton, "word")
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
end

local startButton = gui:add("button", 200, 16, "Start!")

startButton.callback = function()
  server:send("start")
end

game.update = function(self, dt)
  interface = love.keyboard.isDown("tab")
  local ret = false
  while true do
    local event = self.host:service(0)
    if self.connectPending and self.server:state() == "connected" then
      print("Attempting connection")
      self.server:send("list")
      self.server:send("nick" .. ":" .. self.connectPending)
      self.connectPending = false
    end

    if event and event.type == "receive" then
      ret = true

      local t, args = event.data:match("^([^%:]+)%:?(.+)")
      print("Received event of type", t)
      if t == "list" then
        players = {}
        for i, player in ipairs(args:split(":")) do
          players[#players + 1] = {nick = player}
          players[nick] = player
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
        gamestate = "game"
        print(event.data)
        turn = arg:match("^([^%:]+)")
        gui:remove(startButton)
      elseif t == "chat" then
        chat[#chat + 1] = {args:match("^([^%:]+):(.+)")}
      elseif t == "loss" then
        local nick = arg:match("^([^%:]+)%:?(.+)")
        local p = players[nick]
        p.lost = true
        -- handle own loss
      elseif t == "next" then
        local newWord, playerNick, playerTimeLeft = arg:match("^([^%:]*)%:([^%:]+)%:(%d+)%:")
        if #newWord > 0 then
          lastWord = newWord
        end
        turn = playerNick
        player[turn].timeLeft = tonumber(playerTimeLeft)
      elseif t == "victory" then
        -- handle victory
      end
    else
      break
    end
  end

  gui:update(dt)

  return ret
end

game.draw = function(self)
  gui:draw()

  for i = #chat, math.max(1, #chat - 20), -1 do
    local message = chat[i]
    local str = ("%s: %s"):format(message[1], message[2])
    love.graphics.print(str, 200, 660 - (#chat - i)*16)
  end

  love.graphics.print("Players:", 8, 32)
  for i, v in ipairs(players) do
    if v.lost then
      love.graphics.setColor(1/2, 1/2, 1/2)
    else
      love.graphics.setColor(7/8, 7/8, 7/8)
    end
    love.graphics.print(v.nick, 16, 32 + i*16)
  end

  love.graphics.print("Played words:", 1100, 32)
  for i, v in ipairs(words) do
    love.graphics.print(v, 1108, 32+i*16)
  end

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