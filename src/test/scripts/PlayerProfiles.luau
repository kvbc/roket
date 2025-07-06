--#server

local ProfileStore = require(game.ServerScriptService.Packages.ProfileStore)
local Players = game:GetService("Players")

local PlayerProfiles = {}

function PlayerProfiles.RoketStart()
	_G.Profiles = {}

	-- The PROFILE_TEMPLATE table is what new profile "Profile.Data" will default to:
	local PROFILE_TEMPLATE = {
		Cash = 0,
		Deeply = {
			Nested = {
				Data = "hmm",
			},
		},
	}

	local PlayerStore = ProfileStore.New("PlayerStore", PROFILE_TEMPLATE)

	local function PlayerAdded(player)
		-- Start a profile session for this player's data:

		local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		-- Handling new profile session or failure to start it:

		if profile ~= nil then
			profile:AddUserId(player.UserId) -- GDPR compliance
			profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

			profile.OnSessionEnd:Connect(function()
				_G.Profiles[player] = nil
				player:Kick(`Profile session end - Please rejoin`)
			end)

			if player.Parent == Players then
				_G.Profiles[player] = profile
				print(`Profile loaded for {player.DisplayName}!`)
			else
				-- The player has left before the profile session started
				profile:EndSession()
			end
		else
			-- This condition should only happen when the Roblox server is shutting down
			player:Kick(`Profile load fail - Please rejoin`)
		end
	end

	-- In case Players have joined the server earlier than this script ran:
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerAdded, player)
	end

	Players.PlayerAdded:Connect(PlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		local profile = _G.Profiles[player]
		if profile ~= nil then
			profile:EndSession()
		end
	end)
end

function PlayerProfiles.Get(player: Player)
	while not _G.Profiles or not _G.Profiles[player] do
		task.wait(1)
	end
	return _G.Profiles[player]
end

return PlayerProfiles
