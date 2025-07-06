--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roket = require(ReplicatedStorage.Packages.Roket)

local Something = {}

function Something.RoketStart()
	Something.Thing = Roket.NetFunction({ id = "thing" })

	--#server
	Something.Thing:Define(function(returnClient, player, yes)
		if yes then
			returnClient(25)
		else
			returnClient(100)
		end

		task.wait(3)

		return 50
	end)
	--#client
	Something.Thing:Define(function(returnServer, what)
		if what == "age" then
			returnServer(18)
		else
			returnServer("Mark")
		end
	end)
	--#end
end

function Something.Init()
	task.wait(3)

	--#client
	Something.Thing(true):andThen(print)
	task.wait(1)
	Something.Thing(false):andThen(print)
	--#server
	Something.Thing():andThen(warn)
	task.wait(3)
	Something.Thing("age"):andThen(warn)
	--#end
end

--#server
function Something.Important()
	print("secret key: abcdef")
end
--#end

return Something
