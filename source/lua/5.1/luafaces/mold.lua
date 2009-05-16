local string = string
local setmetatable = setmetatable
local error = error
local io = io
local type = type
local tostring = tostring
local next = next
local pairs = pairs

require'tools'

local print_r = tools.print_r

module'luafaces.mold'

local moldsRepository = {} 

repository = repository or setmetatable({}, {
	__index = function(obj, key)
		return find(key) 
	end; 
	
	__newindex = function(...)
		error('illegal operation', 2)
	end
})

function register(key, obj)
	local o = moldsRepository or {}
	string.gsub(key, "[.]?([^.]*)[.]?", function(itemName)
		if itemName ~= "" then
			o[itemName] = o[itemName] or setmetatable({}, {__mode='k'})
			o = o[itemName]
		end
	end)
	o.item = obj
end

function find(key)
	local o = moldsRepository or {}
	string.gsub(key, "[.]?([^.]*)[.]?", function(itemName)
		if itemName ~= "" and o then
			o = o[itemName] or o["*"]
		end
	end)
	
	return o and o.item or o
end


function unregister(key)
	local o = moldsRepository or {}
	local p, name
	string.gsub(key, "[.]?([^.]*)[.]?", function(itemName)
		if itemName ~= "" and o then
			p = o
			name = itemName
			o = o[itemName]
		end
	end)
	if o and p and name then
		p[name] = nil
		return true
	else
		return false
	end
end


function dump()
	print_r(moldsRepository, 'moldsRepository')
end