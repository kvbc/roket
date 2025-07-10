--!strict

local RunService = game:GetService "RunService"

local Roket = {}

Roket.NetEvent = require(script.NetEvent)
-- Roket.NetFunction = require(script.NetFunction)
-- Roket.NetProperty = require(script.NetProperty)
Roket.Trove = require(script.ThirdParty.Trove)
Roket.Promise = require(script.ThirdParty.Promise)
Roket.Addons = {
	NetPropertyStore = require(script.Addons.NetPropertyStore),
}

function Roket.IsServer(): boolean
	return RunService:IsServer()
end

function Roket.IsClient(): boolean
	return RunService:IsClient()
end

function Roket.Start(moduleScriptsParent: Instance)
	for _, child in moduleScriptsParent:GetChildren() do
		if child:IsA("ModuleScript") then
			local module = require(child)
			if type(module) == "table" and module.RoketStart and not child:GetAttribute("__RoketModuleStarted") then
				child:SetAttribute("__RoketModuleStarted", true)
				task.spawn(module.RoketStart)
			end
		end
	end
end

return Roket
