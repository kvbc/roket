--#ignore

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
