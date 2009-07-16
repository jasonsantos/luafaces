--package.path = [[;;../../source/lua/5.1/?.lua;../../source/lua/5.1/?/init.lua;]]

local mask = require'luafaces.mask'
local mold = require'luafaces.mold'
require'util'
-- simple functional masks

mask.define'Main.card' {
	render=function(face, data, r)
		table.insert(r, [[Ace]])
	end;
}

mask.define'naipe' {
	render=function(face, data, r)
		return [[Spades]]
	end;
}

local t = mask.define'Main' [[${card} of ${_naipe}]]

assert(t:render()=='Ace of Spades')
