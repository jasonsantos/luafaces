FACES = {}
FACE_INDEX = {}


DECLARED = {}
UNKNOWN = {}

FREE = {}

LOADING = {}
	
Face = function(name) 
	return function(data) 
		data['.faceName']=name 
		if not FACE_INDEX[name] then
			table.insert(FACES, data)
			local pos = #FACES
			FACE_INDEX[name] = pos
			FACES[pos]=data
		else
			local pos = FACE_INDEX[name]
			for k,v in pairs(data) do
				if FACES[pos][k] then
					print(string.format("Warning: overriding field '%s' of Face '%s'", k, name))
				end
				FACES[pos][k] = v
			end
		end
	end
end

Face'face1'{	
	uses = {
		'one',
		'two',
		'three',
	};
	declares = {
		'four'
	};
}

Face'face2'{	
	uses = {
		'three',
		'four',
		'five',
	};
	declares = {
		'six',
	};
}

Face'face3'{	
	uses = {
		'one',
		'six',
	};
	declares = {
		'seven'
	};
}

Face'face4'{	
	uses = {
		'one',
	};
	declares = {
		'three'
	};
}

Face'face5'{	
	uses = {
		'one',
	};
	declares = {
		'two'
	};
}

Face'face6'{	

	declares = {
		'one'
	};
}

Face'face7'{	
	declares = {
		'five'
	};
}

function addEdge(thisNode, thatNode)
	local name = thatNode['.faceName']
	thisNode['.deps'] = thisNode['.deps'] or {}
	table.insert(thisNode['.deps'], thatNode) 
	thisNode['.deps_table'] = thisNode['.depstable'] or {}
	thisNode['.deps_table'][name] = name
end



table.foreach(FACES, function(k,thisNode) 
	local faceName = thisNode['.faceName']
	print('>', faceName)
	
	function registerUse(_, symbol)
		if not DECLARED[symbol] then
			UNKNOWN[symbol] = UNKNOWN[symbol] or {}
			
			table.insert( UNKNOWN[symbol], thisNode ) -- another module waiting to find out who owns this symbol
		
			print('-- depends on', symbol)
		else
			local declaringNode = DECLARED[symbol]
			
			addEdge(thisNode, declaringNode)
			
			print('-- fulfilled dependency on', symbol)
		end
		
	end

	function registerDeclaration(_, symbol)
		if DECLARED[symbol] then
			print('-- Already declared', symbol)
			--TODO: deal with multiple definitions of a symbol
			return true
		end
		
		print('-- declaring', symbol)
		DECLARED[symbol] = thisNode
		
		local list = UNKNOWN[symbol] or {}
		for _, waitingNode in ipairs(list) do
			local name = waitingNode['.faceName']
			print(name, 'depends on', faceName)
			
			addEdge(waitingNode, thisNode)
			
		end
		UNKNOWN[symbol] = nil
	end

	
	table.foreach(thisNode.declares or {}, registerDeclaration)
	table.foreach(thisNode.uses or {}, registerUse)
	
	-- TODO: add a more sophisticated detection whether this node is free
	if not thisNode['.deps'] or #thisNode['.deps'] <= 0 then
		table.insert(FREE, thisNode)
	end
end)

-- TODO: Check circular dependencies
--[[ Check unfulfilled dependencies
for symbol, dependants in pairs(DEPNODES) do
	if #dependants > 0 then
		s = string.format("Undefined symbol '%s' needed by ", symbol)
		local names = {}
		for _,elem in ipairs(dependants) do
			table.insert(names, elem['.faceName'])
		end
		error(s .. table.concat(names, ', ')) 

	end
end
]]

function size(t)
	local n = 0
	for _,__ in pairs(t) do
		n = n + 1
	end
	return n
end



-- TODO: Check load order
print'Topological Sort'
print(#FREE, 'free nodes')
while #FREE > 0 do
	local target = table.remove(FREE)
	local targetName = target['.faceName']
	table.insert(LOADING, target)
	print('>>> ', targetName)
	local deps = target['.deps'] or {}
	
	for _, name, _ in pairs(deps) do
		print('Name:', name)
		dependants[name]=nil -- this dependency is fullfilled
		if not next(DEPSTO[targetnm]) then
			DEPSTO[targetnm] = nil
			DEPSFRO[name][targetnm] = nil
		end
	end
	for name, node in pairs(DEPSFRO or {}) do
		local nx = next(node) 
		print('Node:', node)
		if not nx then -- if all dependencies are cleared for him
			table.insert(FREE, FACES[ FACE_INDEX[name] ])
		end
	end
end

if #DEPSTO > 0 then
    error"graph has at least one cycle"
else 
    table.foreach(LOADING, print)
end

-- TODO: Check overridden dependencies
-- TODO: Check conflicting dependencies
