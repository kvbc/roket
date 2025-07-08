--!strict
--!optimize 2
--Network Event

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Middleware = require(script.Parent.Middleware)

--[=[
	Network Event

	Allows for client-server communication.

	Base class that all the Roket networking functionality is based on.

	@class NetEvent
]=]
local NetEvent = {}
NetEvent.__index = NetEvent

--[=[
	@interface LoadOptions
	@within NetEvent
	.Id string
	.Unreliable boolean
	.Middlewares { Fire: Middlewares, Listen: Middlewares }
]=]
type LoadOptions = {
	Id: string,
	Unreliable: boolean?,
	Middlewares: {
		Fire: Middleware.Middlewares;
		Listen: Middleware.Middlewares;
	}?
}

--[=[
	Load a Roket network event

	Read more on the [docs](/docs/core_concepts/network_event).

	@return NetEvent
]=]
function NetEvent.Load(optionsOrId: LoadOptions | string)
	local self = setmetatable({}, NetEvent)
	local options: LoadOptions = typeof(optionsOrId) == 'string' and { Id = optionsOrId } or (optionsOrId :: LoadOptions)

	self.id = options.Id
	Middleware.SelfLoad(self, options.Middlewares)

	local remoteEvents = ReplicatedStorage.__Roket.Events
	if RunService:IsServer() then
		local remoteEvent = remoteEvents:FindFirstChild(self.id)
		if not remoteEvent then
			remoteEvent = Instance.new(options.unreliable and "UnreliableRemoteEvent" or "RemoteEvent")
			remoteEvent.Name = self.id
			remoteEvent.Parent = remoteEvents
		end
		self.remoteEvent = remoteEvent
	else
		self.remoteEvent = remoteEvents:WaitForChild(self.id)
	end

	return self
end

--[=[
	Fire a network event
]=]
function NetEvent:Fire(anyOrServerPlayer: Player?, ...: any): ()
	local args = { anyOrServerPlayer, ... }
	if RunService:IsServer() then
		if typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
			self.remoteEvent:FireClient(table.unpack(args))
		else
			self.remoteEvent:FireAllClients(table.unpack(args))
		end
	else
		self.remoteEvent:FireServer(table.unpack(args))
	end
end
Middleware.WrapMethod(NetEvent, "Fire")

--[=[
	Listen to a network event
]=]
function NetEvent:Listen(rawListener: (player: Player?, ...any) -> ()): ()
	local listener = Middleware.SelfWrap(self, rawListener, "Listen")
	if RunService:IsServer() then
		return self.remoteEvent.OnServerEvent:Connect(listener)
	else
		return self.remoteEvent.OnClientEvent:Connect(function(...)
			listener(game.Players.LocalPlayer, ...)
		end)
	end
end

return NetEvent.Load
