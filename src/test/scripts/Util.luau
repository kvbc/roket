--#ignore
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Something = require(script.Parent.Something)
local Roket = require(ReplicatedStorage.Packages.Roket)

local Util = {}

function Util.RoketStart()
	--Util.Print()
end

function Util.Print()
	print("this code is shared!")
	local showErrorEvent = Roket.NetEvent({ id = "show error" })
	local trove = Roket.Trove.new()

	--#server
	print("hello from server")
	Something.Important()
	task.wait(5)
	showErrorEvent:Fire("something went wrong :(")
	task.wait(5)
	showErrorEvent:Fire("still errors")
	task.wait(1)
	showErrorEvent:Fire("here as well")
	task.wait(1)
	showErrorEvent:Fire("but not now!")
	--#client
	print("hello from client")
	trove:Add(showErrorEvent:Listen(function(what: string)
		warn("Got global error from server: '" .. what .. "'")
		if what == "here as well" then
			trove:Destroy()
		end
	end))
	--#end
end

return Util
