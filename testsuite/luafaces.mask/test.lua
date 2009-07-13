--package.path = [[;;../../source/lua/5.1/?.lua;../../source/lua/5.1/?/init.lua;]]

local mask = require'luafaces.mask'
require'util'
-- simple functional masks

mask.define'card' {
	render=function(...)
		return [[ Ace ]]
	end;
}

mask.define'naipe' {
	render=function(...)
		return [[ Spades ]]
	end;
}

local t = mask.define'Main' [[${card} of ${naipe}]]
util.print_r(t)
print(t:render())
