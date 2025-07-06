--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Promise = require(script.Parent.ThirdParty.Promise)

local NetFunction = {}
NetFunction.__index = NetFunction

type LoadOptions = {
	id: string,
}
function NetFunction.Load(opts: LoadOptions)
	local self = setmetatable({}, NetFunction)

	self.id = opts.id

	local remoteFunctions = ReplicatedStorage.__Roket.Functions
	if RunService:IsServer() then
		local remoteFunc = remoteFunctions:FindFirstChild(self.id)
		if not remoteFunc then
			remoteFunc = Instance.new("RemoteFunction")
			remoteFunc.Name = self.id
			remoteFunc.Parent = remoteFunctions
		end
		self.remoteFunction = remoteFunc
	else
		self.remoteFunction = remoteFunctions:WaitForChild(self.id)
	end

	return self
end

function NetFunction:Define(rawFunction: (...any) -> ...any)
	local function onInvoke(...)
		local args = { ... }
		local success, rets = Promise.new(function(resolve)
			rawFunction(resolve, table.unpack(args))
		end):await()
		assert(success)
		return rets
	end

	if RunService:IsServer() then
		self.remoteFunction.OnServerInvoke = onInvoke
	else
		self.remoteFunction.OnClientInvoke = onInvoke
	end
end

function NetFunction:__call(...)
	local args = { ... }
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			if RunService:IsServer() then
				local players = {}
				local explicitPlayer = typeof(args[1]) == "Instance" and args[1]:IsA("Player") and args[1]
				if explicitPlayer then
					table.insert(players, args[1])
					table.remove(args, 1) -- remove first arg (player)
				else
					players = Players:GetPlayers()
				end

				local rets = {}
				for _, player in players do
					rets[player] = self.remoteFunction:InvokeClient(player, table.unpack(args))
				end

				if explicitPlayer then
					return rets[explicitPlayer]
				end
				return rets
			else
				return self.remoteFunction:InvokeServer(table.unpack(args))
			end
		end)
		if success then
			resolve(result)
		else
			reject(result)
		end
	end)
end

return NetFunction.Load
