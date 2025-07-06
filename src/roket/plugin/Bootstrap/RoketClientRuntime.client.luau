--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roket = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Roket"))
Roket.Start(ReplicatedStorage:WaitForChild("__Roket"):WaitForChild("Scripts"))
