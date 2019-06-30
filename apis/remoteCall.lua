local peripheralimpl = {
	["RemoteWrap"] = function ( ... )
		local input = { ... }
		local obj = {}
		obj["cid"] = input[1]
		obj["cside"] = input[2]
		obj["connect"] = function ( ... )
			print("connecting to "..input[1])
			rednet.send(
				input[1],
				textutils.serialize(
					{ "Scheck", input[2] }
				)
			)
			i,m = rednet.receive()
			m = textutils.unserialize(m)
			if not m then
				error("err 0")
			end
			if m[1] == "Rcheck" then
				print("connected to "..input[1])
				print("peripheral type is "..m[2])
				for k,v in pairs(m[3]) do
					obj[v] = function ( ... )
						input = { ... }
						rednet.send(
							obj["cid"],
							textutils.serialize( { v, input } )
						)
						while true do
							s,m = rednet.receive()
							if s == obj.cid then
								if m ~= "nil" then
									return textutils.unserialize(m)
								end
								return
							end
						end
					end
				end
				print("functions synced, peripheral is ready to use!")
			end
		end
		return obj
	end,
	["RemoteCall"] = function ( ... )
		while true do
			s,m = rednet.receive()
			m = textutils.unserialize(m)
			if m[1] == "Scheck" then
				print("client with id "..s.." attempt to connect")
				pcalls = {}
				funcs = peripheral.wrap( m[2] )
				funcs["disconnect"] = function()
					print("client "..s.." disconnected!")
					rednet.send( client, textutils.serialize( "successfully disconnected!" ) )
					peripheral.RemoteCall() --start new
				end
				for k,v in pairs( funcs ) do
					table.insert(pcalls,k)
				end
				rednet.send(
					s,
					textutils.serialize(
						{ "Rcheck", peripheral.getType(m[2]), pcalls }
					)
				)
				print("client connected!")
				client = s
				break
			end
		end
		if client then
			while true do
				s,m = rednet.receive()
				m = textutils.unserialize(m)
					if s == client then
					print("calling peripheral function "..m[1])
					r = funcs[m[1]](unpack(m[2]))
					if r then
						print("returned "..textutils.serialize(r))
					end
					rednet.send(
						client,
						textutils.serialize(r)
					)
				end
			end
		end
	end
}

--PROGRUN
for k,v in pairs(peripheralimpl) do
	peripheral[k] = v
end
