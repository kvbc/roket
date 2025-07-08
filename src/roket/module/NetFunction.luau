--!strict
--!optimize 2

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Promise = require(script.Parent.ThirdParty.Promise)

--[=[
	Wrapper for Roblox's RemoteFunctions

	@class NetFunction
]=]
local NetFunction = {}
NetFunction.__index = NetFunction

--[=[
	@interface LoadOptions
	@within NetFunction
	.id string -- the unique idenitifier
]=]
type LoadOptions = {
	id: string,
}

--[=[
	Load a Roket NetFunction

	Read more on the [docs](/docs/core_concepts/network_event/network_function).

	@return NetFunction
]=]
function NetFunction.Load(optionsOrId: LoadOptions | string)
	local self = setmetatable({}, NetFunction)
	local opts: LoadOptions = type(optionsOrId) == 'string' and { id = optionsOrId } or optionsOrId

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

--[=[
	Define the function on the client, the server, or both

	In the passed function, the `player` is `nil` only when the function is being called locally by the server.

	#### Examples

	See [Examples](/docs/core_concepts/network_event/network_function#examples) in the docs.

	@error ALREADY_DEFINED -- The function has already been defined by the runtime
]=]
function NetFunction:Define(rawFunction: (resolve: (...any) -> ...any, player: Player?, ...any) -> ...any): ()
	assert(not self.rawFunction, `NetFunction "{self.id}" has already defined`)

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

--[=[
	Call the raw defined function locally.

	Can only be called on the client.
	If you meant to locally call the function on the server, just call the function without passing the first "player(s)" arg `myFunction("my data")`

	@error NOT_CLIENT -- The function didn't get called on the client
]=] 
function NetFunction:CallLocal(...: any): ...any
	assert(RunService:IsClient(), `This function should only be called on the client (NetFunction "{self.id}")`)
	local player = game.Players.LocalPlayer
	return self.rawFunction(player, ...)
end

--[=[
	Calls the NetFunction either remotely or locally.
	* *Remotely* being from the Client to the Server or from the Server to the Client(s)
	* *Locally* being ran client-side if executed on the Client or ran server-side if executed on the Server

	When calling the function locally, actual return values are returned instead of a Promise.

	When calling the function remotely, a [Promise](https://eryn.io/roblox-lua-promise/api/Promise) is returned,
	containing either the actual return values
	(if the call was targeted towards a single entity - that is either from Client to Server or from Server to specific Client)
	or a map of `Player -> {...rets}` if the call was targeted to multiple entities (that is from Server to multiple Clients).

	Below is a cheatsheet illustrating when a function is being called remotely or locally,
	and what are it's return values for any given call.

	#### Cheatsheet

	```lua
	--#server
		func(...)              -- local call,                      returns ...rets
		func(player, ...)      -- remote call to specific client,  returns Promise<...rets>
		func([plr1, plr2], ...)-- remote call to specific clients, returns Promise<{[Player]: {...rets}}>
		func(game.Players, ...)-- remote call to all clients,      returns Promise<{[Player]: {...rets}}>
	--#client
		func(...)           -- remote call to the server, returns Promise<...rets>
		func:CallLocal(...) -- local call, returns ...rets
	```

	#### Examples

	```lua
	local MathService = {
		Add = Roket.NetFunction "Add"
	}

	function MathService.RoketStart()
	--#server
		MathService.Add:Define(function(resolve, player, a, b)
			resolve(a + b)
		end)
	--#client
		task.wait(3)
		MathService.Add(3, 5):andThen(print)
	--#end
	end

	return MathService
	```

	See more [Examples](/docs/core_concepts/network_event/network_function#examples) in the docs.

	@return ...any | Promise<...any> | Promise<{[Player]: {...any}}>
]=]
function NetFunction:__call(any_orServerPlayerOrPlayers: Player | {Player} | Players | any, ...: any): ...any
	local args = { any_orServerPlayerOrPlayers, ... }

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
