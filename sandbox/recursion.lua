require'luarocks.require'
require'lpeg'

s = [[
	 %[ one
     %[ two ]%
     %[ three 
             %[ four ]%
          five ]%
      six ]%

]]


local C, Ct, P, R, S, V = lpeg.C, lpeg.Ct, lpeg.P, lpeg.R, lpeg.S, lpeg.V
local SPACE	= S" \t\r\f\n"^0
local OPEN	= P"%["
local CLOSE	= P"]%"
local ITEM, NONITEM, FACE, CONTENT = V'ITEM', V'NONITEM', V'FACE', V'CONTENT'


local GRAMMAR = P{ FACE;
	ITEM    = OPEN * CONTENT * CLOSE,
	NONITEM = C((1-(OPEN + CLOSE))^1),
	CONTENT = (NONITEM + ITEM)^1,
	FACE = Ct( CONTENT )
}

t = GRAMMAR:match(s)

local function print_a(t)
 io.write"{"
 for i, v in ipairs(t) do
   if type(v) == "table" then
     print_a(v)
   else
     io.write(("%q"):format(v))
   end
   if tonumber(i) and t[i + 1] then
     io.write", "
   end
 end
 io.write"}"
end

print_a(t)