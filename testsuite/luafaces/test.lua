package.path = [[;;../../source/lua/5.1/?.lua;../../source/lua/5.1/?/init.lua;]]

require'luafaces'

luafaces.export()

Face'card' {
	render=function(...)
		return [[ Ace ]]
	end;
}

Face'naipe' {
	render=function(...)
		return [[ Spades ]]
	end;
}

