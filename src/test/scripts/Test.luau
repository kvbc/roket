--!strict

local Roket = require(game.ReplicatedStorage.Packages.Roket)
local NetPropertyStore = require(script.Parent.NetPropertyStore)

local Test = {}

function Test.RoketStart()
	Test.Player = NetPropertyStore({
		id = "Player",
	})

	--#server
	while true do
		task.wait(2)
		--Test.Cash:Set(Test.Cash:Get() + 10)
		Test.Player:DeepSet("Deeply.Nested.Data", "howes" .. tostring(math.random(1, 100)))
	end
	--#client
	--Test.Cash:Watch(function(cash)
	--	print("New cash:", cash)
	--end)

	Test.Player:Watch(function(v)
		print(">>>", v)
	end)

	--task.wait(5)

	--print("setting 69")
	--Test.Cash:Set(69)
	--#end
end

return Test
