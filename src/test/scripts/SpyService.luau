--#ignore
local Roket = require(game.ReplicatedStorage.Packages.Roket)

local SpyService = {
    GetClientData = Roket.NetFunction "SpyService.GetClientData"
}

function SpyService.RoketStart()
--#client
    SpyService.GetClientData:Define(function(resolveServer, player, what)
        if what == 'age' then
            return resolveServer(9000)
        elseif what == 'name' then
            return resolveServer('Mark')
        end
    end)
    local age = SpyService.GetClientData:CallLocal('age')
    print(`My age is {age} :)`)
--#server
    task.wait(5)
    local firstPlayer = game.Players:GetPlayers()[1] :: Player
    SpyService.GetClientData(firstPlayer, 'age'):andThen(function(age)
        print(`Age of {firstPlayer.Name} is {age}`)
    end)

    task.wait(5)
    SpyService.GetClientData(game.Players, 'name'):andThen(function(names)
        print("Names of all players are", names)
    end)
--#end
end

return SpyService