--#ignore

local Roket = require(game.ReplicatedStorage.Packages.Roket)

local PingPongService = {
    PingPong = Roket.NetFunction "PingPong"
}

function PingPongService.RoketStart()
--#server
    PingPongService.PingPong:Define(function(resolveClient, player, what)
        if player and what == 'ping' then
            resolveClient('pong')
        end
    end)
    task.wait(3) -- wait a little for players to load
    PingPongService.PingPong(game.Players, 'pong'):andThen(print)
--#client
    PingPongService.PingPong:Define(function(resolveServer, player, what)
        if what == 'pong' then
            resolveServer('ping')
        end
    end)
    task.wait(5)
    PingPongService.PingPong('ping'):andThen(print)
--#end
end

return PingPongService