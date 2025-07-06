--!strict

local RunService = game:GetService("RunService")
local NetEvent = require(script.Parent.NetEvent)
local Middleware = require(script.Parent.Middleware)

type Authority = "server" | "client" | "none"

type Type = {
	Set: (self: Type, newValue: any) -> (),
	Get: (self: Type) -> any,
	Watch: (self: Type, listener: (newValue: any) -> (), firstGet: boolean?) -> (),
}
export type LoadOptions = {
	defaultValue: any?,
	unreliable: boolean?,
	authority: Authority?,
	middlewares: Middleware.Middlewares<Type>?,
}
local NetProperty = {}
NetProperty.__index = NetProperty

function NetProperty.Load(opts: LoadOptions & { id: string }, _defaultOpts: LoadOptions?): Type
	local self = setmetatable({}, NetProperty)

	local defaultOpts: LoadOptions = _defaultOpts or {}

	self.id = opts.id
	self.middlewares = Middleware.MergeWithDefault(opts.middlewares or {}, defaultOpts.middlewares or {})

	self.authority = opts.authority or defaultOpts.authority or "server"
	self.isAuthority = (
		(RunService:IsServer() and self.authority == "server")
		or (RunService:IsClient() and self.authority == "client")
	)

	self.netEvent = NetEvent({
		id = "__RoketNetPropertyChanged",
		unreliable = opts.unreliable or defaultOpts.unreliable,
	})

	self:Set(opts.defaultValue or defaultOpts.defaultValue, nil, true)

	if not self.isAuthority or self.authority == "none" then
		self:Watch(function(newValue: any)
			self:Set(newValue, false)
		end, false)
	end

	self:Set(self:Get(), nil, true)

	return (self :: any) :: Type
end

function NetProperty:GetId()
	return self.id
end

--function NetProperty:DeepGet(path: string): any
--	local names = path:split('.')
--	local object = self.value or {}
--	for index,name in names do
--		if object[name] == nil and index ~= #names then
--			object[name] = {}
--		end
--		if type(object[name]) == 'table' then
--			object = object[name]
--		else
--			return object[name]
--		end
--	end
--	return nil
--end

function NetProperty:DeepSet(path: string, newValue: any)
	local names = path:split(".")
	local topObject = self:Get()
	local object = topObject
	for index, name in names do
		if index ~= #names then
			if object[name] == nil then
				object[name] = {}
			end
			object = object[name]
		else
			object[name] = newValue
		end
	end
	self:Set(topObject)
end

Middleware.DefineMethod(NetProperty, "Set", function(self, newValue: any, fire: boolean?, silenceError: boolean?): ()
	self.value = newValue
	if fire ~= false then
		if self.isAuthority or self.authority == "none" then
			self.netEvent:Fire(self.id, newValue)
		elseif silenceError ~= true then
			local what = RunService:IsServer() and "Server" or "Client"
			error(`{what} has no authority of setting network property "{self.id}" (authority is "{self.authority}")`)
		end
	end
end)

Middleware.DefineMethod(NetProperty, "Get", function(self): any
	return self.value
end)

function NetProperty:Watch(listener: (newValue: any) -> (), firstGet: boolean?): ()
	if firstGet ~= false then
		listener(self:Get())
	end
	return self.netEvent:Listen(function(_, propId: string, newValue: any)
		if propId ~= self.id then
			return
		end
		listener(newValue)
	end)
end

return NetProperty.Load
