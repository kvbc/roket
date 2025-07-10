--#ignore

local Roket = require(game.ReplicatedStorage.Packages.Roket)

local SharedService = {
    Func = Roket.NetFunction "SharedService.Func"
}

function SharedService.RoketStart()
    SharedService.Func:Define(function(resolve, player: Player?, ...)
        print("both do this! and have player", player.Name)
        if Roket.IsClient() then
            print("but client also prints this")
        else
            print("and server this")
        end
        resolve("both return same thing")
    end)

    task.wait(5)

--#server
    SharedService.Func(game.Players):andThen(function(result)
        warn("Server got:", result)
    end)
--#client
    SharedService.Func():andThen(function(result)
        warn("Client got:", result)
    end)
--#end
end

return SharedService