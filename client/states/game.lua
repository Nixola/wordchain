local game = {}

local gui = require "6raphicaluserinterface.src"()
local fonts = require "6raphicaluserinterface.src.utils".font

local colours = require "colours"

local chat = require "game.chat"
local players = require "game.playerList"
local errors = require "game.errors"

local gamestate = "lobby"
local turn
local lastWord
local server
local words = {}
local nick


game.connect = function(self, nick, address, port)

  self.host = enet.host_create()
  local result, r1 = pcall(self.host.connect, self.host, address .. ":" .. port)
  if not result then
    return nil, r1
  end
  self.server = r1
  server = r1
  self.connectPending = nick

  chat:init(gui, r1)

  return self.host
end


local guessSendButton = gui:add("button", 1000, 320, "send")
local guessTextbox    = gui:add("textLine", 200, 320, 790, guessSendButton, "word")
guessTextbox.validate = function(str) return str end

guessSendButton.callback = function(children)
  local newWord = children.word.text
  if #newWord == 0 then return end
  if words[#words] then
    if not words[#words]:valid(newWord) then
      errors:push("This word doesn't work here!")
      return
    elseif words[newWord] then
      errors:push("This word was already played!")
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
      --nick = self.connectPending
      self.connectPending = false
    end

    if not event then break end

    if event.type == "receive" then
      ret = true

      local t, args = event.data:match("^([^%:]+)%:?(.*)")
      print("Received event of type", t, event.data)
      if t == "self" then
        nick = args
        players:init(nick)

      elseif t == "list" then
        players:setList(args:split(":"))

      elseif t == "nick" then
        local oldNick, newNick = args:match("([^%:]+)%:([^%:]+)")
        players:changeNick(oldNick, newNick)

      elseif t == "join" then
        local nick = args:match("([^%:]+)%:")
        players:join(nick)

      elseif t == "start" then
        local startTime
        gamestate = "game"
        turn, startTime = args:match("^([^%:]+)%:(%d+)")
        players:start(turn, startTime)
        gui:remove(startButton)

      elseif t == "chat" then
        chat:receive(args:match("^([^%:]+):(.+)"))

      elseif t == "loss" then
        local lossNick = args:match("^([^%:]+)%:?(.*)")
        players:lost(lossNick)
        if lossNick == players:getSelf().nick then
          lossNick = "You"
        end
        chat:error(("%s lost!"):format(lossNick))
      elseif t == "next" then
        local newWord, playerNick, playerTimeLeft = args:match("^([^%:]*)%:([^%:]+)%:(%d+)%:")
        if #newWord > 0 then
          lastWord = newWord
        end
        words[#words + 1] = newWord
        turn = playerNick
        players:next(playerNick, playerTimeLeft)

      elseif t == "victory" then
        local wonNick = args:match("^([^%:]+)%:?(.*)")
        players:won(wonNick)
        if wonNick == players:getSelf().nick then
          wonNick == "You"
        end
        chat:success(("%s won!"):format(wonNick))
      elseif t == "error" then
        print("Pushing error", args)
        errors:push(args)
      end

    elseif event.type == "disconnect" then
      chat:error("You have been disconnected from the server.")
    end
  end

  gui:update(dt)
  players:update(dt)
  errors:update(dt)

  return ret
end

game.draw = function(self)
  gui:draw()

  --chat
  chat:draw()

  --players
  players:draw()

  --self timer
  local defaultFont = love.graphics.getFont()
  if gamestate == "game" then
    love.graphics.setColor(colours.timer)
    local p = players:getSelf()
    local time = p.timeLeft and string.format("%02d:%02d", p.timeLeft / 60, p.timeLeft % 60) or ""
    love.graphics.setFont(fonts[24])
    love.graphics.print(time, 8, 8)
    love.graphics.setFont(defaultFont)
  end

  love.graphics.setColor(colours.text)
  love.graphics.print("Played words:", 1100, 32)
  for i, v in ipairs(words) do
    love.graphics.print(v, 1108, 32+(#words - i + 1) *16)
  end
  if words[#words] then
    love.graphics.setFont(fonts[24])
    if players:getTurn() == players:getSelf() then
      love.graphics.setColor(colours.wordTurn)
    else
      love.graphics.setColor(colours.wordOther)
    end
    love.graphics.printf(words[#words], 200, 260, 840, "center")
    love.graphics.setFont(defaultFont)
  end
  errors:draw()
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