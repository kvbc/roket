--!strict
--!optimize 2
--Network Event

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Middleware = require(script.Parent.Middleware)
local MiddlewareAgent = require(script.Parent.MiddlewareAgent)
local Trove = require(script.Parent.ThirdParty.Trove)

--[=[
	Network Event

	Allows for client-server communication.

	Base class that all the Roket networking functionality is based on.

	@class NetEvent
]=]
local NetEvent = {}
NetEvent.__index = NetEvent

type NetEventInternals<TArgs> = {
	id: string,
	remoteEvent: RemoteEvent,
	middlewares: NetEventMiddlewares<TArgs>,
	trove: Trove.Trove
}
-- TODO make the above work with composiotnion kinda
-- export type NetEvent<TArgs> = typeof(setmetatable({} :: NetEventInternals<TArgs>, NetEvent))
export type NetEventMiddlewares<TArgs> = {
	Fire: Middleware.MiddlewaresOf<NetEvent_Fire_Middleware<TArgs>>?,
	Listen: Middleware.MiddlewaresOf<NetEvent_Listen_Middleware<TArgs>>?
}

--[=[
	@interface LoadOptions
	@within NetEvent
	.Id string
	.Unreliable boolean
	.Middlewares { Fire: Middlewares, Listen: Middlewares }
]=]
export type LoadOptions<TArgs> = {
	Id: string,
	Unreliable: boolean?,
	Middlewares: NetEventMiddlewares<TArgs>?
}

--[=[
	Load a Roket network event

	Read more on the [docs](/docs/core_concepts/network_event).

	@return NetEvent
]=]
function NetEvent.Load<TArgs>(optionsOrId: LoadOptions<TArgs> | string): NetEvent<TArgs>
	local self = setmetatable({} :: NetEventInternals<TArgs>, NetEvent)
	local options: LoadOptions<TArgs> = typeof(optionsOrId) == 'string' and { Id = optionsOrId } or (optionsOrId :: LoadOptions<TArgs>)

	self.id = options.Id
	self.middlewares = options.Middlewares or {}
	self.trove = Trove.new()

	local remoteEvents = ReplicatedStorage.__Roket.Events
	if RunService:IsServer() then
		local remoteEvent = remoteEvents:FindFirstChild(self.id)
		if not remoteEvent then
			remoteEvent = Instance.new(options.Unreliable and "UnreliableRemoteEvent" or "RemoteEvent")
			remoteEvent.Name = self.id
			remoteEvent.Parent = remoteEvents
		end
		self.remoteEvent = remoteEvent
	else
		self.remoteEvent = remoteEvents:WaitForChild(self.id)
	end

	return self
end

export type NetEvent_Fire_Args<TArgs> = {
	ServerTarget: (Player | {Player})?,
	Args: TArgs,
}
type NetEvent_Fire_Ret = {}
export type NetEvent_Fire_Middleware<TArgs> = Middleware.MiddlewareMethod<NetEvent<TArgs>, NetEvent_Fire_Args<TArgs>, NetEvent_Fire_Ret>
--[=[
	Fire a network event
]=]
function NetEvent.Fire<TArgs>(self: NetEventInternals<TArgs>, args: NetEvent_Fire_Args<TArgs>): NetEvent_Fire_Ret
	return Middleware.CallMethod(self, args, self.middlewares, function(args: NetEvent_Fire_Args<TArgs>): NetEvent_Fire_Ret
		if RunService:IsServer() then
			if args.ServerTarget then
				local players: {Player} = typeof(args.ServerTarget) == 'Instance' and { args.ServerTarget } or (args.ServerTarget :: {Player})
				for _, player in players do
					self.remoteEvent:FireClient(player, args.Args)
				end
			else
				self.remoteEvent:FireAllClients(args.Args)
			end
		else
			self.remoteEvent:FireServer(args.Args)
		end
		return {}
	end)
end

export type NetEvent_Listen_Args<TArgs> = {
	Player: Player?,
	Args: TArgs,
}
type NetEvent_Listen_Ret = {}
export type NetEvent_Listen_Middleware<TArgs> = Middleware.MiddlewareMethod<NetEvent, NetEvent_Listen_Args<TArgs>, NetEvent_Listen_Ret>
--[=[
	Listen to a network event
]=]
function NetEvent.Listen<TArgs>(self: NetEvent, rawListener: (args: NetEvent_Listen_Args<TArgs>) -> ()): RBXScriptConnection
	local function listener(player: Player, args: TArgs)
		local mArgs: NetEvent_Listen_Args<TArgs> = { Player = player, Args = args }
		local key: NetEventMiddlewareKey<TArgs> = "Listen"
		self.middleware:CallMethod(key, mArgs, function(args: NetEvent_Listen_Args<TArgs>): NetEvent_Listen_Ret
			rawListener(args)
			return {}
		end)
	end

	if RunService:IsServer() then
		return self.trove:Add(self.remoteEvent.OnServerEvent:Connect(listener))
	else
		return self.trove:Add(self.remoteEvent.OnClientEvent:Connect(function(args: TArgs)
			listener(Players.LocalPlayer, args)
		end))
	end
end

function NetEvent.Disconnect(self: NetEvent)
	self.trove:Destroy()
end

function NetEvent.Destroy(self: NetEvent)
	self:Disconnect()
	if RunService:IsServer() then
		self.remoteEvent:Destroy()
	end
end

return NetEvent