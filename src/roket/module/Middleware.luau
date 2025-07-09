--!strict
--!optimize 2

--[=[
	@class Middleware

	Middleware singleton utility
]=]
local Middleware = {}

--[[------------------------------------------------------------------------------------------

  _______                    
 |__   __|                   
    | |_   _ _ __   ___  ___ 
    | | | | | '_ \ / _ \/ __|
    | | |_| | |_) |  __/\__ \
    |_|\__, | .__/ \___||___/
        __/ | |              
       |___/|_|              
                       
--]]------------------------------------------------------------------------------------------

export type MethodArgs<TSelf> = { self: TSelf }
export type Method<TSelf, TArgs, TRes> = (TArgs & MethodArgs<TSelf>) -> TRes

--[=[
	@type MiddlewareArgs<TArgs> TArgs & { [string]: any }
	@within Middleware
]=]
export type MiddlewareArgs<TArgs> = TArgs & {
	[string]: any
}
export type MiddlewareArgsMethod<TSelf, TArgs> = MethodArgs<TSelf> & MiddlewareArgs<TArgs>

--[=[
	@type MiddlewareResult<TRes,TArgs> TRes & { next: MiddlewareArgs<TArgs>?, [string]: any }
	@within Middleware
]=]
export type MiddlewareResult<TRes, TArgs> = TRes | {
	next: MiddlewareArgs<TArgs>
}
export type MiddlewareResultMethod<TSelf, TRes, TArgs> = TRes | {
	next: MiddlewareArgsMethod<TSelf, TArgs>
}

--[=[
	@type Middleware<TArgs,TRes> (MiddlewareArgs<TArgs>) -> MiddlewareResult<TRes, TArgs>
	@within Middleware
]=]
export type Middleware<TArgs, TRes> = (MiddlewareArgs<TArgs>) -> MiddlewareResult<TRes, TArgs>
export type MiddlewareMethod<TSelf, TArgs, TRes> = (MiddlewareArgsMethod<TSelf, TArgs>) -> MiddlewareResultMethod<TSelf, TRes, TArgs>
--[=[
	@type Middlewares<TArgs,TRes> Middleware<TArgs,TRes> | { Middleware<TArgs;TRes> }
	@within Middleware
]=]
export type Middlewares<TArgs, TRes> = Middleware<TArgs, TRes> | {Middleware<TArgs, TRes>}
export type MiddlewaresMethod<TSelf, TArgs, TRes> = MiddlewareMethod<TSelf, TArgs, TRes> | {MiddlewareMethod<TSelf, TArgs, TRes>}

export type MiddlewareHandler<TArgs, TRes> = (MiddlewareArgs<TArgs>) -> TRes
export type MiddlewareHandlerMethod<TSelf, TArgs, TRes> = (MiddlewareArgsMethod<TSelf, TArgs>) -> TRes

--[[------------------------------------------------------------------------------------------

  _    _ _   _ _ 
 | |  | | | (_) |
 | |  | | |_ _| |
 | |  | | __| | |
 | |__| | |_| | |
  \____/ \__|_|_|
                 
--]]------------------------------------------------------------------------------------------

local function middlewaresArray<TArgs, TRes>(
	middlewares: Middlewares<TArgs, TRes>
): {Middleware<TArgs, TRes>}
	if typeof(middlewares) == 'function' then
		middlewares = {middlewares}
	end
	return middlewares :: {Middleware<TArgs, TRes>}
end

--[[------------------------------------------------------------------------------------------

  _____                
 |  __ \               
 | |__) |__ ___      __
 |  _  // _` \ \ /\ / /
 | | \ \ (_| |\ V  V / 
 |_|  \_\__,_| \_/\_/  
                       
--]]------------------------------------------------------------------------------------------

--[=[
	Call a raw function with specified middleware and arguments

	#### Examples

	```lua
	--!strict
	--!optimize 2

	-- type PrintSomethingArgs = { Message: string }
	-- type PrintSomethingRet = {}

	local function printSometing(args: PrintSomethingArgs): PrintSomethingRet
		print(args.Message)
		return {}
	end

	local loggerMiddleware: Middleware.Middleware<PrintSomethingArgs, PrintSomethingRet> = function(args)
		args.Message = "[INFO]: " .. args.Message
		return {
			next = args
		}
	end

	Middleware.Call(printSometing, loggerMiddleware, { Message = "Hello" })
	```
]=]
function Middleware.Call<TArgs, TRes>(
	handler: MiddlewareHandler<TArgs, TRes>,
	middlewares: Middlewares<TArgs, TRes>,
	args: MiddlewareArgs<TArgs>
): TRes
	for _, middleware in middlewaresArray(middlewares) do
		local ret = middleware(args)
		if not ret.next then
			return (ret :: any) :: TRes
		end
		args = ret.next :: MiddlewareArgs<TArgs>
	end
	return handler(args)
end

-- just for better typing really
-- not meant to be accessed by the API, instead use MiddlewareAgent
function Middleware.CallMethod<TSelf, TArgs, TRes>(
	handler: MiddlewareHandlerMethod<TSelf, TArgs, TRes>,
	middlewares: MiddlewaresMethod<TSelf, TArgs, TRes>,
	args: MiddlewareArgsMethod<TSelf, TArgs>
): TRes
	assert(args.self, "has self")
	return Middleware.Call(
		handler :: MiddlewareHandler<TArgs, TRes>,
		middlewares :: Middlewares<TArgs, TRes>,
		args -- TODO why no type cast required here?
	)
end

--[=[
	Wrap a raw function to always be called with the specified middleware(s)

	#### Examples

	```lua
	-- ...

	local printNew = Middleware.Wrap(printSometing, loggerMiddleware)

	printNew { Message = "Wassup" }
	```
]=]
function Middleware.Wrap<TArgs, TRes>(
	handler: MiddlewareHandler<TArgs, TRes>,
	middlewares: Middlewares<TArgs, TRes>
): (MiddlewareArgs<TArgs>) -> TRes
	return function(args)
		return Middleware.Call(handler, middlewares, args)
	end
end

return Middleware
