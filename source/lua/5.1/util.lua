pcall('require','luarocks.require')

local lpeg = require'lpeg'

module(..., package.seeall)
 
function string.split (s, sep)
  sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = elem * (sep * elem)^0
  return {lpeg.match(p, s)}
end

function table.add(t, a)
	for i=1,#a do
		table.insert(t,a[i])
	end
	return t
end

function table.clone(t)
	local r = {}
	for k,v in pairs(t) do
		r[k]=v
	end
	return r
end

function table.replace(t, r)
	local n = #r
	for i=1,n do
		t[i]=r[i]
	end
	for j=#t,n+1,-1 do 
		table.remove(t,j)
	end
	return t
end

function iterate(key, fn)
	if type(key)=='string' then
		string.gsub(key, "[.]?([^.]*)[.]?", fn)
	elseif type(key)=='table' then
		for _, itemName in ipairs(key) do
			fn(itemName)
		end
	end
end

function choose(t, s)
	local o = t or {}
	
	iterate(s, function(name)
		o = o and o[name] 
	end)
	
	return o
end

function print_r (t, name, indent)
  local tableList = {}
  function table_r (t, name, indent, full)
    local serial=string.len(full) == 0 and name
        or type(name)~="number" and '["'..tostring(name)..'"]' or '['..name..']'
    io.write(indent,serial,' = ') 
    if type(t) == "table" then
      if tableList[t] ~= nil then io.write('{}; -- ',tableList[t],' (self reference)\n')
      else
        tableList[t]=full..serial
        if next(t) then -- Table not empty
          io.write('{\n')
          for key,value in pairs(t) do table_r(value,key,indent..'\t',full..serial) end 
          io.write(indent,'};\n')
        else io.write('{};\n') end
      end
    else io.write(type(t)~="number" and type(t)~="boolean" and '"'..tostring(t)..'"'
                  or tostring(t),';\n') end
  end
  table_r(t,name or '__unnamed__',indent or '','')
end