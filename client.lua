local threadCode = [[

local channel, errorChannel = ...
local enet = require "enet"


local host = enet.host_create()
local address = channel:peek() or "nixo.la:42068"
local server = host:connect(address)

while true do
	local event = host:service(1000)

	if event and event.type == "receive" then

		print(event.data)
		if event.data:match("^victory") then
			errorChannel:supply("victory")
		end

	end

	if event and event.type == "disconnect" then
		errorChannel:push("disconnected")
	end

	while channel:peek() do
		server:send(channel:pop())
	end

end
]]

local thread = love.thread.newThread(threadCode)
local channel = love.thread.newChannel()
local quit = love.thread.newChannel()

if address then
	channel:push(address)
end

thread:start(channel, quit)

while true do
	channel:push(io.read())
	if quit:peek() then
		love.event.quit()
		break
	end
end