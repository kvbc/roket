# Network Function

## Examples

### Server Authority

```lua
-- @ServerStorage/RoketScripts/MathService

local Roket = require(game.ReplicatedStorage.Packages.Roket)

local MathService = {
	CalcDelta = Roket.NetFunction "MathService.CalcDelta",
}

function MathService.RoketStart()
--#server
    MathService.CalcDelta:Define(function(resolveClient, player, a, b, c)
        local delta = b*b - 4*a*c
        if player then
            -- return to client after 2 seconds
            print(`Calculating delta for {player.Name} with {a}, {b}, and {c}`)
            task.wait(2)
            resolveClient(delta, 619)
        end
        return delta, 420 -- return to server immediately
    end)
    task.wait(2)
    local a, b, c = 6, 1, 9
    local delta, other = MathService.CalcDelta(a, b, c)
    print(`Server delta is {delta} ({other})`)
--#client
    local a, b, c = 7, 1, 10
    print("Waiting for delta calculation ...")
    task.wait(5)
    print("That's enough! I want my delta!")
    MathService.CalcDelta(a, b, c):andThen(function(delta, other)
        print(`My delta is {delta} ({other})`)
    end)
--#end
end

return MathService
```

### Client Authority

```lua
-- @ServerStorage/RoketScripts/SpyService

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
```

### Two-Way Communication

```lua
-- @ServerStorage/RoketScripts/PingPongService

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
```

### Shared Definition

```lua
-- @ServerStorage/RoketScripts/SharedService

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
```

### OOP

...

### Multiple Files

...
