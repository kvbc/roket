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
function NetFunction.Load(optsOrId: LoadOptions | string)
	local self = setmetatable({}, NetFunction)
	local opts: LoadOptions = type(optsOrId) == 'string' and { id = optsOrId } or optsOrId

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
		local rets = {Promise.new(function(promiseResolve)
			-- wrapper to let `return resolve(...)` work
			local function resolve(...)
				promiseResolve(...)
				return ...
			end
			-- insert the dummy local player to stabilize raw func def
			if RunService:IsClient() then
				table.insert(args, 1, Players.LocalPlayer)
			end
			rawFunction(resolve, table.unpack(args))
		end):await()}
		local success = table.remove(rets, 1)
		assert(success, "Promise did not resolve successfully")
		return table.unpack(rets)
	end

	self.rawFunction = function(...)
		-- dummy resolve
		local function resolve(...)
			return ...
		end
		return rawFunction(resolve, ...)
	end

	if RunService:IsServer() then
		self.remoteFunction.OnServerInvoke = onInvoke
	else
		self.remoteFunction.OnClientInvoke = onInvoke
	end
end

function NetFunction:CallLocal(...)
	assert(RunService:IsClient(), "This function should only be called on the client")
	local player = game.Players.LocalPlayer
	return self.rawFunction(player, ...)
end

function NetFunction:__call(...)
	local args = { ... }

	if RunService:IsServer() then
		local players = {}
		local explicitPlayer = typeof(args[1]) == "Instance" and args[1]:IsA("Player") and args[1]
		if explicitPlayer then
			players = { explicitPlayer }
			table.remove(args, 1)
		elseif args[1] == Players then
			players = Players:GetPlayers()
			table.remove(args, 1)
		end

		if #players > 0 then
			return Promise.new(function(resolve)
				local rets = {}
				for _, player in players do
					rets[player] = self.remoteFunction:InvokeClient(player, table.unpack(args))
				end
				if explicitPlayer then
					resolve(rets[explicitPlayer])
				else
					resolve(rets)
				end
			end)
		else
			local player = nil
			return self.rawFunction(player, table.unpack(args))
		end
	else
		-- client
		return Promise.new(function(resolve)
			resolve(self.remoteFunction:InvokeServer(table.unpack(args)))
		end)
	end
end

return NetFunction.Load
