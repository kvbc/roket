--!strict
--Network Event

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NetEvent = {}
NetEvent.__index = NetEvent

type LoadOptions = {
	id: string,
	unreliable: boolean?,
}
function NetEvent.Load(optsOrId: LoadOptions | string)
	local self = setmetatable({}, NetEvent)
	local opts: LoadOptions = type(optsOrId) == 'string' and { id = optsOrId } or optsOrId

	self.id = opts.id

	local remoteEvents = ReplicatedStorage.__Roket.Events
	if RunService:IsServer() then
		local remoteEvent = remoteEvents:FindFirstChild(self.id)
		if not remoteEvent then
			remoteEvent = Instance.new(opts.unreliable and "UnreliableRemoteEvent" or "RemoteEvent")
			remoteEvent.Name = self.id
			remoteEvent.Parent = remoteEvents
		end
		self.remoteEvent = remoteEvent
	else
		self.remoteEvent = remoteEvents:WaitForChild(self.id)
	end

	return self
end

function NetEvent:Fire(...: any): ()
	if RunService:IsServer() then
		local arg1 = ({ ... })[1]
		if typeof(arg1) == "Instance" and arg1:IsA("Player") then
			self.remoteEvent:FireClient(...)
		else
			self.remoteEvent:FireAllClients(...)
		end
	else
		self.remoteEvent:FireServer(...)
	end
end

function NetEvent:Listen(listener: (serverPlayer: Player?, ...any) -> ()): ()
	if RunService:IsServer() then
		return self.remoteEvent.OnServerEvent:Connect(listener)
	else
		return self.remoteEvent.OnClientEvent:Connect(function(...)
			listener(nil, ...)
		end)
	end
end

return NetEvent.Load
