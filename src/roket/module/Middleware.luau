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

type Self = {middlewares: KeyedMiddlewares, [string]: any}
type MethodArgs<TArgs> = TArgs & { Self: Self }
type Method<TArgs, TRes> = (Self, TArgs) -> TRes

--
-- Public
--

--[=[
	@type MiddlewareArgs<TArgs> TArgs & { [string]: any }
	@within Middleware
]=]
export type MiddlewareArgs<TArgs> = TArgs & {
	[string]: any
}
--[=[
	@type MiddlewareResult<TRes,TArgs> TRes & { next: MiddlewareArgs<TArgs>?, [string]: any }
	@within Middleware
]=]
export type MiddlewareResult<TRes, TArgs> = TRes & {
	next: MiddlewareArgs<TArgs>?;
	[string]: any
}
--[=[
	@type Middleware<TArgs,TRes> (MiddlewareArgs<TArgs>) -> MiddlewareResult<TRes, TArgs>
	@within Middleware
]=]
export type Middleware<TArgs, TRes> = (MiddlewareArgs<TArgs>) -> MiddlewareResult<TRes, TArgs>
--[=[
	@type Middlewares<TArgs,TRes> Middleware<TArgs,TRes> | { Middleware<TArgs;TRes> }
	@within Middleware
]=]
export type Middlewares<TArgs, TRes> = Middleware<TArgs, TRes> | {Middleware<TArgs, TRes>}
--[=[
	@type KeyedMiddlewares {[string]: Middlewares<any;any>}
	@within Middleware
]=]
export type KeyedMiddlewares = {[string]: Middlewares<any, any>?}

--[[------------------------------------------------------------------------------------------

  _    _ _   _ _ 
 | |  | | | (_) |
 | |  | | |_ _| |
 | |  | | __| | |
 | |__| | |_| | |
  \____/ \__|_|_|
                 
--]]------------------------------------------------------------------------------------------

local function middlewaresArray<TArgs, TRes>(middlewares: Middlewares<TArgs, TRes>): {Middleware<TArgs, TRes>}
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
		args.Message = "[LOG]: " .. args.Message
		return {
			next = args
		}
	end

	Middleware.Call(printSometing, loggerMiddleware, { Message = "Hello" })
	```
]=]
function Middleware.Call<TArgs, TRes>(
	rawFunction: (TArgs) -> TRes,
	middlewares: Middlewares<TArgs, TRes>,
	args: TArgs
): TRes
	for _, middleware in middlewaresArray(middlewares) do
		local ret = middleware(args :: MiddlewareArgs<TArgs>)
		if not ret.next then
			return ret
		end
		args = ret.next
	end
	return rawFunction(args)
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
	rawFunction: (TArgs) -> TRes,
	middlewares: Middlewares<TArgs, TRes>
): (TArgs) -> TRes
	return function(args)
		return Middleware.Call(rawFunction, middlewares, args)
	end
end

--[[------------------------------------------------------------------------------------------

   _____      _  __ 
  / ____|    | |/ _|
 | (___   ___| | |_ 
  \___ \ / _ \ |  _|
  ____) |  __/ | |  
 |_____/ \___|_|_|  
                    
--]]------------------------------------------------------------------------------------------

--[=[
	Call

	#### Examples

	```lua
	function Car:Build(args: { Colors: string }) 
		return Middleware.SelfCallMethod(self, 'Build', args, function(args)
			print(`Building my car of color {args.Colors}`)
			return 'abc'
		end)
	end
	```
]=]
function Middleware.SelfCallMethod<TArgs, TRes>(self: Self, methodName: string, args: TArgs, rawMethod: Method<TArgs, TRes>): TRes
	local middlewares = Middleware.SelfGetKey(self, methodName)
	return Middleware.CallMethod(self, rawMethod, middlewares or {}, args)
end

--[=[
	Load specified middlewares into `self`

	#### Examples

	```lua
	local Car = {}

	function Car.New()
		local self = {}

		Middleware.SelfLoad(self, { Start = print })

		return self
	end

	-- function Car.Start() ... end

	return Car
	```
]=]
function Middleware.SelfLoad(self: {[any]: any}, middlewares: KeyedMiddlewares): ()
	(self :: Self).middlewares = middlewares
end

--[=[
	Wrap a raw function to always be called with middleware(s) attached to specific key in `self`

	Useful when creating higher-order functions such as in the example(s) below

	#### Examples

	```lua
	local Car = {}

	function Car.New()
		local self = {}

		Middleware.SelfLoad(self, { Listen = print })

		return self
	end

	function Car:Listen(listener)
		listener = Middleware.SelfWrap(self, listener, 'Listen')
		-- ...
	end

	return Car
	```
]=]
function Middleware.SelfWrap<TArgs, TRes>(
	self: Self,
	rawFunction: (TArgs) -> TRes,
	middlewaresKey: string
): (TArgs) -> TRes
	return function(args)
		local middlewares = Middleware.SelfGetKey(self, middlewaresKey)
		return Middleware.Call(rawFunction, middlewares or {}, args)
	end
end

--[=[
	Get specified middlewares from `self`

	#### Examples

	```lua
	local Car = {}

	function Car.New()
		local self = {}

		Middleware.SelfLoad(self, { Thing = warn })

		local middlewares = Middleware.SelfGetKey(self, "Thing")
		print(middlewares) -- warn

		return self
	end

	return Car
	```
]=]
function Middleware.SelfGetKey<TArgs, TRes>(self: Self, middlewaresKey: string): Middlewares<TArgs, TRes>?
	local middlewares = Middleware.SelfGet(self)
	return middlewares[middlewaresKey]
end

--[=[
	Get middlewares from `self`

	#### Examples

	```lua
	local Car = {}

	function Car.New()
		local self = {}

		Middleware.SelfLoad(self, { Thing = warn })

		local middlewares = Middleware.SelfGet(self)
		print(middlewares) -- { "Thing": warn }

		return self
	end

	return Car
	```
]=]
function Middleware.SelfGet(self: Self): KeyedMiddlewares
	assert(self.middlewares, "self must have middlewares otherwise it was not loaded")
	return self.middlewares
end

--[[------------------------------------------------------------------------------------------

  __  __      _   _               _ 
 |  \/  |    | | | |             | |
 | \  / | ___| |_| |__   ___   __| |
 | |\/| |/ _ \ __| '_ \ / _ \ / _` |
 | |  | |  __/ |_| | | | (_) | (_| |
 |_|  |_|\___|\__|_| |_|\___/ \__,_|

--]]------------------------------------------------------------------------------------------

--[=[
	Call a raw method with specified middleware and arguments
]=]
function Middleware.CallMethod<TArgs, TRes>(
	self: Self,
	rawMethod: Method<TArgs, TRes>,
	middlewares: Middlewares<MethodArgs<TArgs>, TRes>,
	args: TArgs
): TRes
	local function rawFunction(methodArgs: MethodArgs<TArgs>): TRes
		return rawMethod(methodArgs.Self, methodArgs)
	end
	local methodArgs = args :: MethodArgs<TArgs>
	methodArgs.Self = self
	return Middleware.Call(rawFunction, middlewares, methodArgs)
end

--[=[
	Wrap a method to always be called with midleware(s) attached to specific key in `self`
]=]
function Middleware.WrapMethod<TArgs, TRes>(object: {[any]: any}, methodName: string): ()
	local method = object[methodName] :: Method<TArgs, TRes>
	assert(typeof(method) == 'function', `method "{methodName}" must be a function`)
	local wrap: Method<TArgs, TRes> = function(self, args)
		local middlewares = Middleware.SelfGetKey(self, methodName)
		return Middleware.CallMethod(self, method, middlewares or {}, args)
	end
	object[methodName] = wrap
end

-- function Middleware.Join<Self>(current: Middlewares<Self>, default: Middlewares<Self>)
-- 	for key, value in pairs(default) do
-- 		if not current[key] then
-- 			current[key] = default[key]
-- 		else
-- 			local function unpackIfTable(value)
-- 				if type(value) == "table" then
-- 					return table.unpack(value)
-- 				end
-- 				return value
-- 			end
-- 			current[key] = { unpackIfTable(default[key]), unpackIfTable(current[key]) }
-- 		end
-- 	end
-- 	return current
-- end

return Middleware
