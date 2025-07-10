--#ignore
--!strict

local Roket = require(game.ReplicatedStorage.Packages.Roket)
--#server
local PlayerProfiles = require(script.Parent.PlayerProfiles)
--#end

return function(opts)
	return Roket.NetProperty(opts, {
		--#server
		middlewares = {
			Get = function(self)
				return false, PlayerProfiles.Get(game.Players:WaitForChild("zo_ofil")).Data
			end,
			Set = function(self, newValue, ...)
				if type(newValue) ~= "table" then
					return false
				end
				PlayerProfiles.Get(game.Players:WaitForChild("zo_ofil")).Data = newValue
				return true, newValue, ...
			end,
		},
		--#end
	})
end
