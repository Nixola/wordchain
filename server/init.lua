assert(config, "Don't run this file directly!")
config.time = tonumber(config.time) or 300

local enet = require "enet"

local bans = {}
local peers_by = {ip = {}, id = {}, order = {}, nick = {}}
local peer_id = {}

local f = io.open("wordlist", "r")
local wordlist = {}
for word in f:lines() do
	wordlist[word] = true
end

local host = enet.host_create("0.0.0.0:42068")

local state = "lobby"
local words = {}
local turn = 1
local players = {}

local time
local lastGuessTime
local finished = false
while true do
	time = os.time()
	local send = {}
	local event = host:service(100)

	if finished then
  	for i, v in ipairs(peers_by.order) do
			v.obj:disconnect()
		end
		--peers_by = {ip = {}, id = {}, order = {}}
		--peer_id = {}
		state = "lobby"
		words = {}
		turn = 1
		players = {}
		finished = false
	end

	if time ~= otime and state == "game" then
		local player = players[turn]
		player.timeLeft = player.timeLeft - 1
		if player.timeLeft <= 0 then
			send[#send + 1] = {broadcast = true, "loss", player.nick, player.nick .. " lost!"}
			table.remove(players, turn)
			turn = (turn - 1) % #players + 1
			if #players > 1 then
				local msg = words[#words] and ('Word to chain onto is "' .. words[#words] .. '"!') or "Choose a first word!"
				send[#send + 1] = {broadcast = true, "next", words[#words] or "", players[turn].nick, players[turn].timeLeft, msg}
			end
		end
		if #players == 1 then
			send[#send + 1] = {broadcast = true, "victory", players[1].nick, players[1].nick .. " won!"}
			finished = true
		end
	end

  if event and event.type == "connect" then
    local ip = tostring(event.peer)
    print("Incoming connection", ip)
    if not ip then
      print("Can't figure out IP. Like hell I'm letting this through.")
      event.peer:reset()
    else
      ip = ip:match("^(.-)%:%d+$")
      if bans[ip] then
        print("Banned IP attempted joining")
        event.peer:reset()
      else
        local id = event.peer:connect_id()
        local p = {id = id, nick = id, ip = ip, obj = event.peer, latency = "n/a"}
        peers_by.ip[ip] = p
        peers_by.id[id] = p
        table.insert(peers_by.order, p)
        peer_id[event.peer] = id
        --players[#players + 1] = p
        print("Connecting", id)
        send[#send + 1] = {"self", id}
        send[#send + 1] = {broadcast = true, "join", id, "\"" .. id .. "\" joined the game!"}
        peers_by.nick[id] = p
        if state == "game" then
          p.lost = true
          p.timeLeft = 0
          send[#send + 1] = {"start", players[turn].nick, players[turn].timeLeft, "The game has already started."}
          send[#send + 1] = {broadcast = true, "loss", id, id .. " joined as spectator!"}
        end
      end
    end
  elseif event and event.type == "receive" then
    local result
    local action, arg = event.data:match("^([^%:]+)%:?(.-)$")
    local peerID = event.peer:connect_id()
    local peer = peers_by.id[peerID]
    print("Received event", action, "from", event.peer)

    if action == "chat" then
    	send[#send + 1] = {broadcast = true, "chat", peers_by.id[peerID].nick, arg}
    elseif action == "list" then
      local playerNicks = {"list"}
      for i, v in ipairs(peers_by.order) do
        print("list", i, v)
        table.insert(playerNicks, v.nick)
      end
      send[#send + 1] = playerNicks
    elseif action == "nick" and (state == "lobby" or (peer and peer.nick == peer.id))  then
      if peers_by.nick[arg] then
        send[#send + 1] = {"error", "Your nick is already in use."}
      else
    	  local oldNick = peers_by.id[peerID].nick
    	  peers_by.id[peerID].nick = arg
          peers_by.nick[oldNick] = nil
          peers_by.nick[arg] = peers_by.id[peerID]
    	  send[#send + 1] = {broadcast = true, "nick", oldNick, arg, oldNick .. " changed name to \"" .. arg .. "\"!"}
      end
    elseif action == "start" and state == "lobby" then
    	state = "game"
    	for i, p in ipairs(peers_by.order) do
    		players[#players + 1] = p
    		p.timeLeft = config.time
    	end
    	lastGuessTime = time
    	send[#send + 1] = {broadcast = true, "start", players[1].nick, config.time, "The game has started! " .. players[1].nick .. " may choose a word."}
    elseif action == "word" and state == "game" and players[turn].id == peerID then
    	if not wordlist[arg] then
    		send[#send + 1] = {"error", "\"" .. arg .. "\" isn't a valid word!"}
    	elseif (not words[#words]) or words[#words]:valid(arg) then
    		if words[arg] then
    			send[#send + 1] = {"error", "\"" .. arg .. "\" was already played! Try again!"}
    		else
    			local oldPlayer = players[turn]
    			lastGuessTime = time
    			words[#words + 1] = arg
    			words[arg] = true
    			turn = turn % #players + 1
    			send[#send + 1] = {broadcast = true, "next", arg, players[turn].nick, players[turn].timeLeft, "\"" .. oldPlayer.nick .. "\" sent \"" .. arg .. "\"!"}
    		end
    	else
    		send[#send + 1] = {"error", "\"" .. arg .. "\" is not a word you can chain right now."}
    	end
    end
  elseif event and event.type == "disconnect" then
    local peerID = peer_id[event.peer]
    peer_id[event.peer] = nil
    local nick = peers_by.id[peerID].nick
    --peers_by.nick[nick] = nil
    peers_by.id[peerID].nick = ""
    for i, v in ipairs(peers_by.order) do
    	if v.id == peerID then
    		table.remove(peers_by.order, i)
    		break
    	end
    end
    for i, v in ipairs(players) do
    	if v.id == peerID then
    		table.remove(players, i)
    		break
    	end
    end
    local ev = {"disconnect", tostring(peerID), broadcast = true}
    send[#send + 1] = ev
  end

  --[[if time ~= otime then --broadcast a latency update
    local t = {type = "latency", broadcast = true, data = {}}
    for id, p in pairs(peers_by.id) do
      if p.nick ~= "" then --the peer is online
        local ping = p.obj:round_trip_time()
        t.data[id] = ping
        p.latency = ping
      end
    end
    if send then --append the event
      send[#send+1] = t
    else -- need sendin'
      send = {t}
    end
  end--]]


  if send then
    for i, ev in ipairs(send) do
      local packet = table.concat(ev, ":")
      if ev.broadcast then
        host:broadcast(packet)
      else
        event.peer:send(packet)
      end
    end
  end

  otime = time
end
