require'luarocks.require'
require'lpeg'

s = [[

%[-------1 before
	%[ 2 inner test ]%
	after----]%
	
	%[ 3 standalone test  ]%

]]


local template = {}

local content=function(content, ...)
	local t = {...}
	print(content)
	if #t > 0 then
		print'###########'
		print('[', string.sub(content, t[1], t[2]), ']')
	end
end 

local WHITESPACE = lpeg.S'\f \t\r\n'

local NUM = lpeg.R'09'

local SPACE = (WHITESPACE^0)

local OP = lpeg.P'%['
local CL = lpeg.P']%'

local CONTENT, ITEM, DEF = lpeg.V'CONTENT', lpeg.V'ITEM', lpeg.V'DEF'

local TEMPLATE = lpeg.P{
	CONTENT,
	CONTENT	= SPACE * ((1-(OP+CL))^1 + ITEM )^1 * SPACE,
	ITEM  = lpeg.Cp() * OP * (lpeg.C(CONTENT) / content )* CL * lpeg.Cp()
}

lpeg.match(TEMPLATE, s)