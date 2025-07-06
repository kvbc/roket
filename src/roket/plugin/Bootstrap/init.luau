--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")

type Scope = "shared" | "client" | "server"
type ScopeSources = { client: string, server: string }

local function ensureEmptyFolder(parent: Instance, name: string): Folder
	local folder = parent:FindFirstChild(name)
	if folder then
		assert(folder:IsA("Folder"))
		folder:ClearAllChildren()
		return folder
	else
		local newFolder = Instance.new("Folder")
		newFolder.Name = name
		newFolder.Parent = parent
		return newFolder
	end
end

local function insertModuleScript(parent: Instance, name: string, source: string)
	if #source == 0 then
		return
	end
	assert(not parent:FindFirstChild(name))
	local newScript: ModuleScript = Instance.new("ModuleScript")
	newScript.Name = name
	newScript.Parent = parent
	newScript.Source = source
end

local function getSourceLineScope(line: string): Scope?
	local function matches(directive: string): boolean
		return line:match("^%s*--%s*#" .. directive) ~= nil
	end
	if matches("server") then
		return "server"
	end
	if matches("client") then
		return "client"
	end
	if matches("end") then
		return "shared"
	end
	return nil
end

local function splitSource(source: string): ScopeSources
	local sources: ScopeSources = {
		client = "",
		server = "",
	}
	local scope: Scope = "shared"
	for _, line in source:split("\n") do
		local newScope: Scope? = getSourceLineScope(line)
		if newScope then
			scope = newScope
		elseif scope == "shared" then
			sources.client ..= line .. "\n"
			sources.server ..= line .. "\n"
		else
			sources[scope] ..= line .. "\n"
		end
	end
	return sources
end

--
-- Public
--

local function Bootstrap()
	local serverFolder = ensureEmptyFolder(ServerScriptService, "__Roket")
	local serverScriptsFolder = ensureEmptyFolder(serverFolder, "Scripts")
	do
		local serverRuntime = script.RoketServerRuntime:Clone()
		serverRuntime.Parent = serverFolder
		serverRuntime.Enabled = true
	end

	local clientFolder = ensureEmptyFolder(ReplicatedStorage, "__Roket")
	local clientScriptsFolder = ensureEmptyFolder(clientFolder, "Scripts")
	ensureEmptyFolder(clientFolder, "Events")
	ensureEmptyFolder(clientFolder, "Functions")
	do
		local clientRuntime = script.RoketClientRuntime:Clone()
		clientRuntime.Parent = ensureEmptyFolder(StarterPlayer.StarterPlayerScripts, "__Roket")
		clientRuntime.Enabled = true
	end

	for _, child in ServerStorage.RoketScripts:GetChildren() do
		if child:IsA("ModuleScript") then
			local sources = splitSource(child.Source)
			insertModuleScript(serverScriptsFolder, child.Name, sources.server)
			insertModuleScript(clientScriptsFolder, child.Name, sources.client)
		end
	end
end

return Bootstrap
