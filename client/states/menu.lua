local menu = {}
local DNS = require "dns"
local dns = DNS()

local gui = require "6raphicaluserinterface.src"()
local stop
local nick, addr, err, stopb

local colours = require "colours"

local fonts = require "6raphicaluserinterface.src.utils".font

local connecting = {}

menu.helpString = [[
Hi! If you're reading this, you may be wondering how to use this wonderful piece of software.
First of all, connect to a server. Choose a nickname, type in the address and connect. Once connected, you'll find yourself in a lobby. Provided I didn't fuck anything up, you should see a list of connected players. By design, anyone can start the game! You might not like that. Make a pull request.
After a player starts the game by clicking the button or sending the "/start" command (don't know which, I haven't decided yet while writing this thing), whoever connected first will have to choose a first word. The player after that will then have to choose a word which starts with the end of that word, then the player after that needs to do the same, etc.
Each player has a timer, which only ticks down during their turn. When a player's timer reaches zero, that player is automatically disqualified and the turn passes over to the next one. Only one will remain.
Don't take the lazy path! Words with only the first/last letter in common will take 5 seconds from your timer!
I'm planning on expanding the UI (including, but not limited to, a mobile interface), so you're free to suggest me stuff to add/fix over at https://github.com/Nixola/wordchain! (No clickable link because lazy.)
Enjoy!]]

love.graphics.setBackgroundColor(colours.background)

local connect = function(children)
	if connecting.resolving or connecting.ip then return end
	local n = children.nick.text
	local a = children.address.text

	local host, port = a:match("^(.-)%:(%d+)$")
	if not host then
		err = "Malformed URL"
		return
	else
		port = port or 42069
	end

	local nick = n:match("^([^%:]+)$")
	if not nick then
		err = "Invalid nick"
		return
	else
		n = nick
	end

	dns:resolve(host)

	connecting = {resolving = host, nick = n, port = port}

	stopb = gui:add("button", 32, 390, "Stop")
	stopb.callback = stop
end


stop = function()
	dns:stop()
	dns = DNS()
	connecting = {}
	gui:remove(stopb)
end


local timer = 0

--err  = gui:newLabel(32, 290, "", {255, 0, 0})
local connectButton = gui:add("button", 148, 370, "Connect!")
connectButton.callback = connect
nick = gui:add("textLine", 32, 310, 178, connectButton, "nick")
addr = gui:add("textLine", 32, 340, 178, connectButton, "address")
nick.validate = function(str) return str end
addr.validate = function(str) return str end

addr.text = config.address and (config.address:match("%:%d+$") and config.address or (config.address .. ":42068")) or "nixo.la:42068"


menu.update = function(self, dt)
	timer = timer + dt
	if connecting.resolving then
		local ip, e = dns:resolved()
		if ip then
			local e
			connecting.resolving = nil
			connecting.host, e = states.game:connect(connecting.nick, ip, connecting.port)
			if not connecting.host then
				err = e
				gui:remove(stopb)
			else
				connecting.ip = ip
			end
		end
	end


	if connecting.ip then
		if states.game:update(dt) then
			connecting.ip = nil
			connecting.port = nil
			gui:remove(stopb)
			state = states.game
		end
	end

	gui:update(dt)
end


menu.draw = function(self)
	if connecting.resolving then
		love.graphics.setColor(colours.warning)
		love.graphics.printf("Resolving...", 32, 400, 178, "center")
	elseif connecting.ip then
		love.graphics.setColor(colours.success)
		love.graphics.printf("Connecting...", 32, 400, 178, "center")
	end
	if connecting.resolving or connecting.ip then
		for i = -0.5, 0.5, 0.2 do
			local a = (math.cos((timer +i) % math.pi) + 1) * math.pi
			local x, y = 32 * math.sin(a) + 116, 32 * math.cos(a) + 456
			love.graphics.circle("fill", x, y, 3, 9)
		end
	end
	gui:draw()
	love.graphics.setColor(colours.gray7)
	love.graphics.setFont(fonts[32])
	love.graphics.printf("Wordchain", 240, 16, 600, "left")
	local font = fonts[12]
	love.graphics.setFont(font)
	love.graphics.printf(self.helpString, 240, 64, 600, "left")
	love.graphics.setColor(colours.uiLines)
	local _, wrap = font:getWrap(self.helpString, 600)
	local height = font:getHeight() * #wrap
	love.graphics.line(230, 16, 230, 64 + height + 8)
	if err then
		love.graphics.setColor(colours.error)
		love.graphics.print(err, 32, 290)
	end
end


menu.mousepressed = function(self, x, y, b)
	gui:mousepressed(x, y, b)
end

menu.mousereleased = function(self, x, y, b)
	gui:mousereleased(x, y, b)
end


menu.keypressed = function(self, k, kk)
	gui:keypressed(k, kk)
end


menu.textinput = function(self, char)
	gui:textinput(char)
end

return menu