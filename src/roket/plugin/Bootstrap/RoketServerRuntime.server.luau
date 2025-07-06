--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Roket = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Roket"))
Roket.Start(ServerScriptService:WaitForChild("__Roket"):WaitForChild("Scripts"))
