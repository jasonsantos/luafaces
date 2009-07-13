require"luarocks.require"
--require"cosmo"
require"lpeg"

function string.split (s, sep)
  sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = lpeg.Ct(elem * (sep * elem)^0)   -- make a table capture
  return lpeg.match(p, s)
end

local template = [==[
<select name='cliente'>
  $cliente[[
  <option value="$id">$label</option>
]]
</cliente>
]==]
--[[--
print(cosmo.fill(template, {
	cliente = {
		{id=1, label='Jason'},
		{id=2, label='André'},
		{id=3, label='Leonardo'},
		{id=4, label='Alessandro'},
		{id=5, label='Ricardo'},
		{id=6, label='Bruno'},
	}
}))
--]]--

--[==[--
local luafaces = require"luafaces"

luafaces.export(_G)

Face"html.select.cliente" [[
	${{item{
	<option value="$id">$label</option>
}}}
]]

local f = luafaces.compile("html.select.cliente", print)

print(f{
	cliente = {
		{id=1, label='Jason'},
		{id=2, label='André'},
		{id=3, label='Leonardo'},
		{id=4, label='Alessandro'},
		{id=5, label='Ricardo'},
		{id=6, label='Bruno'},
	}
})

--]==]--




s = [[
${{@context{net.quantumsatis.faces}}}

	${{testezero}}

	${{testeum{}}}

	${{testebase{Assim n�o tem condi��es}}}

	${{teste{
		This is a test for you ${1}
		Name: ${2}, ${1}
	}}}

	${{testoptions{
		This is a test for me ${1}
		-- how would I paste this text
		${{item{
			Name: ${2}, ${1}
		}}}
		-- replace the item and then print the next text in the right place?
		And it suddenly appeared before me.
	}}}

	${{combobox{
		<select id="${id}" name="${name}" class="${class}" style="${style}">   
		${{option{
			<option value="${value}">${name}</option>
		}}}
		</select>
	}}}

	${combobox{id="novo"}}

	${combobox{id="velho", class="invisible"}}

	${teste}

	${{testezeroum}}
	
	${teste{
		${.teste2{
			"fulano"
		}},
		${.teste2{
			"de tal"
		}}
	}}

]]

--[[--
local open = "${" * lpeg.Cg(lpeg.P"="^0, "init") * "{" * lpeg.P"\n"^-1
local close = "}" * lpeg.C(lpeg.P"="^0) * "}"

local face = open * m.C((lpeg.P(1))^0) * close /  function (o, s) return s end
--]]--

--[[--

--]]--


local alpha =  lpeg.R('__','az','AZ','\127\255') 
local n = lpeg.R'09'
local alphanum = alpha + n

local space = (lpeg.S'\n \t\r\f')^0



local def_EMPTYopening = lpeg.P"${{" * lpeg.C((alphanum + '.')^1 / print)  
local def_EMPTYclose = lpeg.P"}}"

local def_opening = lpeg.P"${{" * lpeg.C((alphanum + '.')^1 / print)  * lpeg.P"{" 
local def_close = lpeg.P"}}}"
--[[---
local definition = (1-def_opening)^0 * def_opening * lpeg.C((1-def_close)^0) * def_close 

name, content = lpeg.match(definition, s)

print('name', name)
print('content', content)
--]]--

	-- variables
	-- -------------------------------

	facesread = {}
	context = {}
	stack = {}


	-- handlers
	-- -------------------------------

	local open=function(name) 
		
		table.insert(stack, name)
		
		local facename = table.concat(stack, ".")
		
		facesread[facename] =  {
			['.prototype'] = 'face';
			['.faceName'] = name;
			source = '';
			template = {};--[[
				[1] text
				[2] reftable : {[.prototype]='faceref', [face]='as.asd.dff', [parameters]={a,b,c, name=value}}
				[3] text
			]]
			requires = {};
			declares = {};
		}
	end
	
	local close=function(...) 
		local toclose = table.remove(stack, #stack)
	end

	local empty=function(...) open(...) close(...)  end

	
	local text=function(...)
		local chunks = {...}
		for _,content in pairs(chunks) do
			print('[[', content, ']]')
		end  
		if #stack > 0 then
			local facename = table.concat(stack, ".")
		
			table.insert(facesread[facename].template, content)
		end
	end
	
	local init=function(contextName) 
		print('init', contextName)
		for name in pairs(string.split(contextName, '.')) do
			if name~='' then
				table.insert(context, name)
			end 
		end 
	end

	local use=function(...) print('use', ...) end
	local use_with_parameters=function(...) print('use()', ...) end
	
	
	-- patterns
	-- -------------------------------
	
	local use_open=lpeg.P('${')

	local def_open=lpeg.P('${{')
	local op=lpeg.P('{')
	local cl=lpeg.P('}')
	local def_close=lpeg.P('}}')
	
	local space=lpeg.S(" \t\r\n")
	
	local letter=lpeg.R("az", "AZ")
	local namecharstart=letter + '_' + '.'
	local numeral = lpeg.R("09")^1
	local name=namecharstart * (namecharstart + lpeg.R("09") )^0

	local initialization = (space^0 * def_open * "@context" * op * lpeg.C(name) * cl * def_close  ) / init
	
	local def_opening_element=(space^0 * def_open * lpeg.C(name) * op ) / open
	local def_closing_element=(space^0 * cl * def_close) / close
	local def_empty_element=space^0 * def_open * lpeg.C(name)  * space^0 * def_close / empty

	local opening_element=(space^0 * use_open * lpeg.C(name) * op ) 
	local closing_element=(space^0 * def_close) 
	
	local single_variable=space^0 * use_open * lpeg.C(name + numeral)  * space^0 * cl / use

	local plain = space^0 * lpeg.P((single_variable + (1 - (def_open + def_close)) )^1) * space^0
	local parameter =  lpeg.C( plain ) * lpeg.P(',')^-1
	local parametrized_variable=space^0 * use_open * lpeg.C(name + numeral) * op * space^0 * parameter^0 * cl * cl / use_with_parameters
	local content = lpeg.P{
		[1]=space^0 * lpeg.C((lpeg.V(5) + (1 - (def_open + def_close)) )^1) * space^0 / text,
		[2]=single_variable, 
		[3]=space^0 * use_open * lpeg.C(name + numeral) * op * space^0 * lpeg.V(4)^0 * cl * cl / use_with_parameters,
		[4]=lpeg.C( lpeg.V(1) ) * lpeg.P(',')^-1,
		[5]=lpeg.V(2) + lpeg.V(3)
	}
	
	
	local template=lpeg.P{
		[1]=initialization^0 * lpeg.V(4),
		[2]=def_opening_element * lpeg.V(4)^0 * def_closing_element,
		[3]=opening_element * lpeg.V(4)^0 * closing_element,
		[4]=(def_empty_element + content + lpeg.V(2) + lpeg.V(3))^1,		
	}


	
--[[	
	local singelton_element=(space^0 * lt * lpeg.C(name) * 
		attribute^0 * space^0 * slash *gt) / single
		
	local content=space^0 * ((lpeg.P(1) - lt)^1) * space^0 / text
	
	local cdata=(space^0 * cdata_start  * 
		lpeg.C((lpeg.P(1) -cdata_end)^1) * cdata_end )/cdata
		
	local comment_element=(space^0 * comment_open * 
		lpeg.C((lpeg.P(1) - comment_close)^0) * comment_close) / comment

	local xml=lpeg.P{
		[1]=declaration^0 * lpeg.V(2),
		[2]=opening_element * lpeg.V(3)^0 * closing_element,
		[3]=comment_element^1 + singelton_element^1 
			+ content + cdata + lpeg.V(2),
	}

	
	if xml:match(xmlstr) then
		return stack[1]
	else
		return nil,"Parse error"
	end
end
	
--]]--


lpeg.match(template, s)
print'-----------------------------------'
table.foreach(facesread, function(k,v)
	print(k)
	table.foreach(v.template, function(kk,vv)
		print('>', kk, vv)
	end)
end)