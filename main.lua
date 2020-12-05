love.load = function(args)
	if args[1] == "--server" then
		require "server"
	elseif args[1] == "--client" then
		address = args[2]
		require "client"
	else
		print("Specify either --server or --client <address:port>")
		love.event.quit()
	end
end