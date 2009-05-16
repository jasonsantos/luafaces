local mask = require'luafaces.mask'
local mold= require'luafaces.mold'

module('luafaces', package.seeall)

path = path or './faces/?.facefile'

--- Returns a mask 
Face = function(facename)
	return mask.define(facename)
end

--- sets the public repository for quick access to loaded faces
repository = setmetatable({}, {
	__index = function(_, facename)
		--TODO: include support for facefiles
		return mask.repository[facename]
	end
})

--- export this module public symbols to the calling environment
function export(context)
	local context = context or getfenv(2)
	for k,v in pairs(_M) do
		context[k]=v
	end
	return context
end


function render(f,data,rederer,context)
	if type(f)=='table' then
		face,data,rederer,context = f.face,f.data,f.rederer,f.context
	else
		face = f 
	end
	
	
end