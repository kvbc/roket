--!strict
--!optimize 2

local Middleware = require(script.Parent.Middleware)

--
--
--
--
--

--[=[
	@class MiddlewareAgent

	Middleware Agent

	#### Examples

	```lua
		-- local Middleware = ...
		-- local MiddlewareAgent = ...

		local Logger = {}
		Logger.__index = Logger
		--type LoggerInternals = {
		--     middleware: MiddlewareAgent.MiddlewareAgent<Logger>
		-- }
		--type Logger = typeof(setmetatable({} :: LoggerInternals, Logger))
		--type LoggerMiddlewares = {
		--     Log: Middleware.MiddlewaresMethod<Logger, LoggerLogArgs, LoggerLogRet>
		-- }

		------------------------------------------------------

		function Logger.New(middlewares: LoggerMiddlewares?): Logger
			local self = setmetatable({} :: LoggerInternals, Logger)
			self.middleware = MiddlewareAgent.New(self, middlewares or {})
			return self
		end

		--type LoggerLogArgs = { Message: string }
		--type LoggerLogRet = {}
		function Logger.log(self: Logger, args: LoggerLogArgs): LoggerLogRet
			print(args.Message)
			return {}
		end
		function Logger.Log(self: Logger, args)
			return self.middleware:CallMethod('Log', args, function(args: LoggerLogArgs): LoggerLogRet
				return self:log(args)
			end)
		end

		------------------------------------------------------

		do
			local logger = Logger.New()
			logger:Log { Message = "thats a normal log" }
		end

		do
			local screamMiddleware: Middleware.MiddlewareMethod<Logger, LoggerLogArgs, LoggerLogRet> = function(args)
				args.self:log { Message = "FOR THE GLORY OF MY HOMELAND" }
				args.Message = `RAAAH, {args.Message:upper()}!!!`
				return {
					next = args
				}
			end
			local logger = Logger.New({ Log = screamMiddleware })
			logger:Log { Message = "Hello" }
			logger:log { Message = "vs. normal hello :)" }
		end
	```
]=]
local MiddlewareAgent = {}
MiddlewareAgent.__index = MiddlewareAgent

type MiddlewareAgentInternals<TSelf> = {
	target: Target<TSelf>,
}
export type MiddlewareAgent<TSelf> = typeof(setmetatable({} :: MiddlewareAgentInternals<TSelf>, MiddlewareAgent))

--
--
--
--
--

type Target<TSelf> = { __middlewares: TargetMiddlewares<TSelf> }
--[=[
	@type TargetMiddlewares<TSelf> {[string]: Middlewares<TSelf, any, any>?}
	@within MiddlewareAgent
]=]
export type TargetMiddlewares<TSelf> = {[string]: Middleware.MiddlewaresMethod<TSelf, any, any>?}

--
--
--
--
--

function MiddlewareAgent.New<TSelf>(target: any, middlewares: TargetMiddlewares<TSelf>): MiddlewareAgent<TSelf>
	local target = target :: Target<TSelf>
	assert(not target.__middlewares, "should not exist")
	target.__middlewares = middlewares
	
	local self = (setmetatable({}, MiddlewareAgent) :: any) :: MiddlewareAgent<TSelf>
	
	self.target = target
	
	return self
end

function MiddlewareAgent:GetMiddlewares<TSelf>(): TargetMiddlewares<TSelf>
	local self = self :: MiddlewareAgent<TSelf>
	return self.target.__middlewares
end

function MiddlewareAgent:GetMethodMiddlewares<TSelf, TArgs, TRes>(methodName: string): Middleware.MiddlewaresMethod<TSelf, TArgs, TRes>
	local self = self :: MiddlewareAgent<TSelf>
	local middlewares = self:GetMiddlewares()[methodName] :: Middleware.MiddlewaresMethod<TSelf, TArgs, TRes>?
	return middlewares or {}
end

function MiddlewareAgent:CallMethod<TSelf, TArgs, TRes>(
	methodName: string,
	args: Middleware.MiddlewareArgs<TArgs>,
	method: Middleware.Method<TSelf, TArgs, TRes>
): TRes
	local self = self :: MiddlewareAgent<TSelf>
	local middlewares: Middleware.MiddlewaresMethod<TSelf, TArgs, TRes> = self:GetMethodMiddlewares(methodName)
	local args = args :: Middleware.MiddlewareArgsMethod<TSelf, TArgs>
	args.self = (self.target :: any) :: TSelf
	return Middleware.CallMethod(method, middlewares, args)
end

return MiddlewareAgent