love.load = function(args)
	if args[1] == "--server" then
		require "server"
	elseif args[1] == "--client" then
		address = args[2]
		require "client"
	else
		print("--server or --client wasn't specified - defaulting to --client nixo.la:42068")
		require "client"
	end
end