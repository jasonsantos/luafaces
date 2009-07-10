require'luarocks.require'
require'lpeg'

function show(t, name, indent)
   local cart     -- a container
   local autoref  -- for self references

   --[[ counts the number of elements in a table
   local function tablecount(t)
      local n = 0
      for _, _ in pairs(t) do n = n+1 end
      return n
   end
   ]]
   -- (RiciLake) returns true if the table is empty
   local function isemptytable(t) return next(t) == nil end

   local function basicSerialize (o)
      local so = tostring(o)
      if type(o) == "function" then
         local info = debug.getinfo(o, "S")
         -- info.name is nil because o is not a calling level
         if info.what == "C" then
            return string.format("%q", so .. ", C function")
         else 
            -- the information is defined through lines
            return string.format("%q", so .. ", defined in (" ..
                info.linedefined .. "-" .. info.lastlinedefined ..
                ")" .. info.source)
         end
      elseif type(o) == "number" then
         return so
      else
         return string.format("%q", so)
      end
   end

   local function addtocart (value, name, indent, saved, field)
      indent = indent or ""
      saved = saved or {}
      field = field or name

      cart = cart .. indent .. field

      if type(value) ~= "table" then
         cart = cart .. " = " .. basicSerialize(value) .. ";\n"
      else
         if saved[value] then
            cart = cart .. " = {}; -- " .. saved[value] 
                        .. " (self reference)\n"
            autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
         else
            saved[value] = name
            --if tablecount(value) == 0 then
            if isemptytable(value) then
               cart = cart .. " = {};\n"
            else
               cart = cart .. " = {\n"
               for k, v in pairs(value) do
                  k = basicSerialize(k)
                  local fname = string.format("%s[%s]", name, k)
                  field = string.format("[%s]", k)
                  -- three spaces between levels
                  addtocart(v, fname, indent .. "   ", saved, field)
               end
               cart = cart .. indent .. "};\n"
            end
         end
      end
   end

   name = name or "__unnamed__"
   if type(t) ~= "table" then
      return name .. " = " .. basicSerialize(t)
   end
   cart, autoref = "", ""
   addtocart(t, name, indent)
   return cart .. autoref
end


local C, Cc, Ct, Cg, Cb, P, R, S, V = lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cg, lpeg.Cb, lpeg.P, lpeg.R, lpeg.S, lpeg.V


-- internal parser
-- -----------------------

-- Tokens

local FACENAMETOKEN = {'FACENAME'}

local WHITESPACE = S'\f \t\r\n'^0

local NUM = R'09'
local NAMESTARTCHAR	= R"AZ" + "_" + R"az"
local NAMECHAR	= NAMESTARTCHAR + NUM
local NAME = NAMESTARTCHAR * NAMECHAR^0 
local DOT = P"."
local WILDCARD = P"*" + "-"  
local FACENAME = (DOT^0 * (WILDCARD + NAME))^1  
local FACEUSENAME = (DOT^0 * NAME)^1 

local ALPHA =  R('__','az','AZ','\127\255') 

local ALPHANUM = ALPHA + NUM

local NUMBER = (P'.' + NUM)^1 * (S'eE' * S'+-'^-1)^-1 * (ALPHANUM)^0
NUMBER = #(NUM + (P'.' * NUM)) * NUMBER

local SPECIALFUNCTION = lpeg.P"${@" * lpeg.C(NAME) * lpeg.P"[" * lpeg.C(FACEUSENAME) * lpeg.P"]}" ^1 

local OPENBRACKETS = P"["^1 * P"\n"^-1
local OPENBRACES = P"{"^1
local CLOSEBRACES = P"}"^1 -- TODO: add support for long braces
local FACEDEFSTART = P"${" * Cc(FACENAMETOKEN) * C(FACENAME) * OPENBRACKETS
local FACEDEFEND = P"]"^1 * "}" 

local FACEUSESTART = P"${" * C(FACEUSENAME) * OPENBRACES
local FACEUSEEND = P"}"^0 * "}" 


local ITEM, NONITEM, FACE, CONTENT = V'ITEM', V'NONITEM', V'FACE', V'CONTENT'


local GRAMMAR = P{ FACE;
	ITEM    = FACEDEFSTART * FACE * FACEDEFEND,
	NONITEM = C((1-(FACEDEFSTART + FACEDEFEND))^1),
	CONTENT = (NONITEM + ITEM)^1,
	FACE = Ct( CONTENT )
}


s = [[
zero zero
	 ${one[ 1
     	${one.two[2]}
	     ${one.three[ description of 3
            ${one.three.four[4]}
          back to 3 ]}
     ]}
zero zero
]]


t = GRAMMAR:match(s)

function createFaces(T)
	local t = {}
	local faceName 
	for i, v in pairs(T) do
		if type(v)=='table' then
			if v==FACENAMETOKEN then
				faceName = T[i+1]
				T[i]=nil
				T[i+1]=nil
				i = i + 2
			else
				local o = createFaces(v)
				o.faceName = faceName
				if tonumber(i) then
					table.insert(t, o)
				end
			end
		else
			table.insert(t, T[i])
		end
	end
	return t
end

print(show(createFaces(t)))
