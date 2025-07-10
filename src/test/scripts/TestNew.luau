--!strict
--!optimize 2

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local NetEvent = require(ReplicatedStorage.Packages.Roket.NetEvent)
local Middleware = require(ReplicatedStorage.Packages.Roket.Middleware)

local highlightMiddleware: NetEvent.NetEvent_Fire_Middleware<TestNew_Notify_Args> = function(args)
    args.Args.Message = `[[ {args.Args.Message} ]]`
    return {
        next = args
    }
end

local listenMiddleware: NetEvent.NetEvent_Listen_Middleware<TestNew_Notify_Args> = function(args)
    return {}
end

type TestNew_Notify_Args = { Message: string }
local TestNew = {
    Notify = NetEvent.Load({
        Id = "NetEventNotify",
        Middlewares = {
            Fire = highlightMiddleware,
        }
    } :: NetEvent.LoadOptions<TestNew_Notify_Args>)
}

function TestNew.RoketStart()
    print("started!")

--#server
    task.wait(3)
    TestNew.Notify:Fire({
        Args = {
            Message = "Hello!!",
        }
    } :: NetEvent.NetEvent_Fire_Args<TestNew_Notify_Args>)
--#client
    TestNew.Notify:Listen(function(args: NetEvent.NetEvent_Listen_Args<TestNew_Notify_Args>)
        print(`> {args.Args.Message}`)
    end)
--#end
end

return TestNew