--!strict

local RoketBootstrap = require(script.Bootstrap)
local RunService = game:GetService("RunService")

local toolbar = plugin:CreateToolbar("Roket")
local button = toolbar:CreateButton("Bootstrap", "Bootstrap Roket", "rbxassetid://4458901886")

button.Click:Connect(function()
	RoketBootstrap()
end)

button.ClickableWhenViewportHidden = true

task.spawn(function()
	while true do
		task.wait(5)
		if RunService:IsStudio() and RunService:IsEdit() then
			RoketBootstrap()
		end
	end
end)
