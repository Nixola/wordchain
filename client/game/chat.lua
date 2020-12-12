local colours = require "colours"
local chat = {}

chat.init = function(self, gui, server)
	self.gui = gui
	self.server = server
	self.initialized = true
	self.messages = {}

	local chatSendButton = gui:add("button", 1000, 680, "send")
	local chatTextbox    = gui:add("textLine", 200, 680, 790, chatSendButton, "message")
	chatTextbox.validate = function(str) return str end

	chatSendButton.callback = function(children)
		local msg = children.message.text
		if #msg == 0 then return end
		server:send("chat:" .. msg)
		children.message:clear()
	end
end


chat.receive = function(self, nick, message)
	assert(self.initialized, "Init the chat first!")
	self.messages[#self.messages + 1] = ("%s: %s"):format(nick, message)
end


chat.error = function(self, message)
	assert(self.initialized, "Init the chat first!")
	self.messages[#self.messages + 1] = {colours.error, message}
end


chat.success = function(self, message)
	assert(self.initialized, "Init the chat first!")
	self.messages[#self.messages + 1] = {colours.success, message}
end

chat.draw = function(self)
	assert(self.initialized, "Init the chat first!")
	love.graphics.setColor(colours.uiLabels)

	local defaultFont = love.graphics.getFont()
	love.graphics.print("Chat", 216, 660 - 16*16)

	local chatLineHeight = 660 - 16*16 + defaultFont:getHeight() / 2 + .5
	love.graphics.setLineWidth(1)
	love.graphics.line(210 - .5, chatLineHeight, 192 - .5, chatLineHeight, 192 - .5, 720 + .5)
	love.graphics.line(216 + defaultFont:getWidth("Chat") + 6 + .5, chatLineHeight, 1042 + .5, chatLineHeight, 1042 + .5, 720 + .5)

	love.graphics.setColor(colours.text)
	for i = #self.messages, math.max(1, #self.messages - 15), -1 do
		local message = self.messages[i]
		love.graphics.print(message, 200, 660 - (#self.messages - i)*16)
	end
end

return chat