--!strict

local Middleware = {}

type Method<Self> = (self: Self, ...any) -> (boolean, ...any) -- returns first if should go next
export type Middlewares<Self> = { [string]: Method<Self> | { Method<Self> } }

function Middleware.DefineMethod<T>(object: { [any]: any }, key: string, method: T): ()
	object[key] = function(self, ...)
		local middlewares = (self.middlewares and self.middlewares[key]) or {}
		if typeof(middlewares) == "function" then
			middlewares = { middlewares }
		end
		local args = { ... }
		for _, middleware in middlewares do
			local rets = { middleware(self, table.unpack(args)) }
			local goNext = table.remove(rets, 1)
			assert(typeof(goNext) == "boolean")
			if not goNext then
				return table.unpack(rets)
			end
			if #rets > 0 then
				args = rets
			end
		end
		return method(self, table.unpack(args))
	end
end

function Middleware.MergeWithDefault<Self>(current: Middlewares<Self>, default: Middlewares<Self>)
	for key, value in pairs(default) do
		if not current[key] then
			current[key] = default[key]
		else
			local function unpackIfTable(value)
				if type(value) == "table" then
					return table.unpack(value)
				end
				return value
			end
			current[key] = { unpackIfTable(default[key]), unpackIfTable(current[key]) }
		end
	end
	return current
end

return Middleware
