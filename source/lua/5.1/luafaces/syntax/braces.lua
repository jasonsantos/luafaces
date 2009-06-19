---module(..., package.seeall)
require'luarocks.require'
local lpeg = require'lpeg'

--[=[

# Faces Standard Syntax


## Defining a face

A face can be defined inside any template string by this simple syntax.

      ${facename[  face content  ]}

After the square bracket all whitespace before the first newline (inclusive) is ignored, allowing this (more elegant) alternative approach.

      ${other.facename[
      other face content
      ]}

If you must use brackets inside the face definition, you can increase the redundancy of the parser by adding more square brackets:

     ${yet.another.face[[[
	 adding more and more content [this time with brackets]
	 ]]]}


## using a face

Using a face is easy. You simply call it from any template string and it will be replaced by its value during render.

     ${facename}

Alternatively you can use a face inside a face definition. This is called 'referring', and creates a dependency between the declared and the used faces.

      ${other.facename[
      other face content dedicated to ${username}
      ]}

When using a face with references, you can fill those references by parameter passing directly on using it:

      ${other.facename{username=[Jack Bauer]}}

You can use square brackets or quotes to indicate string parameters:

      ${faces.faces.everywhere{id=' 123', class="justified", username=[Jack Bauer]}}

References can come from other faces or from data tables included on code-behind events. You can also use references as parameter values.

      ${page[
			${header{user=${username}}}
			${body}
			${footer}
      ]}

## Nested, relative and masked faces

You can declare a face inside another face. When doing that you create two faces, relative to each other (the inner face being an extension of the outer face)
and is also considered to be referenced by the outer face. In other words, you create relative faces and use them at the same location.

      ${product[
	     ${vendor[Ilyich Ulianov Enterprises]} ${name[Prianik Medoviy]}
	  ]}

Faces declared or used inside another face are resolved relatively to the outside face.

      ${user[
			${id[1]}
			${name[
				${first[Jack]} ${last[Bauer]}
			]}
		]}

		${user.name.last} == Bauer

To use a full-named face, you must reference its name beginning with an underline ('_')

      ${page.myaccount.header[
		${title}
		${_user.name}
		${changepassword.button}
	  ]}

Faces declared inside another face are considered to be used in that position as well. To declare a face but not use it, the face must be declared with double braces. 

      ${page.history.header[
		${{message[
			${icon} - ${message}
		]}}
		${previous.button} ${next.button}
		
		${message}
	  ]}


You can declare a face to treat different cases using wildcards on face definition. These are called 'template faces'. A template face will be selected if no specific face is found for a given facename.

      ${*.name.standard[
			${lastname}, ${firstname}
      ]}

	  ${user.name.standard{firstname=[Fulano], lastname=[de Tal]}}


You can also use the minus character ('-') to declare template faces.

      ${page.-.header[
		${title}
		${_user.name}
	  ]}

## Special instructions

There are special instructions that can be given while declaring faces. These special faces are functions that can be run during the parsing phase. These special functions begin with an 'at' character ('@').


### @context

When parsing faces and subfaces the engine changes context every time a new face level is entered. When declaring faces inside faces. The context function alters the default context of the parser -- this way it is possible to declare several faces in an arbitrary context. The context is reset when the current context is closed.

       ${@context[page.header]}




]=]---


--- external API

onfacedef = function(context, facename, dependencies, templatetable)
	error'uninitialized face declaration event'
end

onfaceuse = function(context, facename, parameters)
	error'uninitialized face use event'
end

onfacerender = function(context, facename, templatetable, data)
	error'uninitialized face render event'
end

onparsespecial = function(context, functionname)
	error'uninitialized face render event'
end


function string.split (s, sep)
  sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = elem * (sep * elem)^0
  return {lpeg.match(p, s)}
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


-- internal parser
-- -----------------------

-- Tokens

local WHITESPACE = lpeg.S'\f \t\r\n'^0

local NUM = lpeg.R'09'
local NAMESTARTCHAR	= lpeg.R"AZ" + "_" + lpeg.R"az"
local NAMECHAR	= NAMESTARTCHAR + NUM
local NAME = NAMESTARTCHAR * NAMECHAR^0 
local DOT = lpeg.P"."
local WILDCARD = lpeg.P"*" + "-"  
local FACENAME = (DOT^0 * (WILDCARD + NAME))^1  
local FACEUSENAME = (DOT^0 * NAME)^1 

local ALPHA =  lpeg.R('__','az','AZ','\127\255') 

local ALPHANUM = ALPHA + NUM

local NUMBER = (lpeg.P'.' + NUM)^1 * (lpeg.S'eE' * lpeg.S'+-'^-1)^-1 * (ALPHANUM)^0
NUMBER = #(NUM + (lpeg.P'.' * NUM)) * NUMBER

-- variables
-- --------------

local faces = { _={} }
local stack = { level = 0 }
local context = { level = 0 }
local stacks = { stack }
local mainstack = stacks[ #stacks ]
local currentFace = faces['_']

local templatestack = {}

local specialFunctions = {
	context = function(facename)
		local newstack = string.split(facename, '.')  
		newstack.level = #newstack
		table.insert(stacks, newstack)
		stack = stacks[#stacks]
	end
}


local function fullName(facename, exclusive)
	local namestack = stack
	local t = {}
	for k,v in ipairs(namestack) do
		t[k] =v
	end
	local splitname = string.split(facename, '.')
	for _, namepart in ipairs(splitname) do
		table.insert(t, namepart)
	end
	if exclusive then
		table.remove(t, #t)
	end
	return table.concat(t, '.'), splitname
end

local N = fullName

-- TODO: rewrite to a better, closure-based parser

--- pushes the facename to the control stacks of the parser
local function pushname(facename)
	local fullname, splitname = N(facename)
	for _, namepart in ipairs(splitname) do
		table.insert(stack, namepart)
		stack.level = stack.level + 1
	end
	-- sets the control reference variables to the right face
	faces[fullname] = faces[fullname] or {
		['.type']='face',
		['fullname']=fullname,
		['facename'] = stack[#stack],
	} -- creates a new face if necessary -- TODO: use the 'create new face 'API
	local lastFace = currentFace
	currentFace = faces[fullname]
	currentFace.lastFace = lastFace
end


local function popname(facename)
	local fullname, splitname = N(facename, true)
	for _, namepart in ipairs(splitname) do
		if stack.level < 1 then
			table.remove(stacks, #stacks)
			stack = stacks[#stacks]
		else
			table.remove(stack, #stack)
			stack.level = stack.level - 1
		end
	end
	local lastFace = currentFace.lastFace
	currentFace.lastFace = nil
	currentFace = lastFace 
end

faceuse = function(name, paramstr)
print'---faceuse-------------'print(name)
	local fullname = N(name) print('fullname:',fullname)
	if paramstr then print('params:', paramstr) end
	currentFace.uses = currentFace.uses or {}
	currentFace.uses[fullname] = true
end

special = function(fnname, paramstr)
print'---special-------------'
	local fn = specialFunctions[fnname]
	if fn and type(fn)=='function' then
		fn(paramstr)
	end
end

faceopen = function(facename, ...)
print'---faceopen-------------'print(facename, ...)
	pushname(facename)
	-- adds to the 'tag' context (this is different from the stack because one tag can enter multiple face levels)
	table.insert(context, facename)
	context.level = context.level + 1
end

facecontent = function(startpos, content, endpos)
print'---facecontent-------------'
	print('pos:', startpos, endpos)
	currentFace.source = content
end

faceclose = function(...)
print'---faceclose-------------'print(context[#context])print(context.level)
	local facename = context[#context] or '_'
	popname(facename)
	table.remove(context, #context)
	context.level = context.level - 1
end


local SPECIALFUNCTION = lpeg.P"${@" * lpeg.C(NAME) * lpeg.P"[" * lpeg.C(FACEUSENAME) * lpeg.P"]}" ^1 

local OPENBRACKETS = lpeg.P"["^1 * lpeg.P"\n"^-1
local OPENBRACES = lpeg.P"{"^1
local CLOSEBRACES = lpeg.P"}"^1 -- TODO: add support for long braces
local FACEDEFSTART = lpeg.P"${" * lpeg.C(FACENAME) * OPENBRACKETS
local FACEDEFEND = lpeg.P"]"^1 * "}" 

local FACEUSESTART = lpeg.P"${" * lpeg.C(FACEUSENAME) * OPENBRACES
local FACEUSEEND = lpeg.P"}"^0 * "}" 

-- Face Use Parameters
local SPACE = (WHITESPACE^0)

local SIMPLEFACEUSE = lpeg.P"${" * lpeg.C(FACEUSENAME) * "}" 

local STRING = (lpeg.P'"' * ( (lpeg.P'\\' * 1) + (1 - (lpeg.S'"\n\r\f')) )^0 * lpeg.P'"') +
  (lpeg.P"'" * ( (lpeg.P'\\' * 1) + (1 - (lpeg.S"'\n\r\f")) )^0 * lpeg.P"'")

local LITERAL = STRING + NUMBER

local ATTR = FACEUSENAME * SPACE * "=" * SPACE * LITERAL

local PARAMS = ATTR * ("," * ATTR)^0 

local PARAMFACEUSE = lpeg.P"${" * lpeg.C(FACEUSENAME) * OPENBRACES * lpeg.C(PARAMS) * CLOSEBRACES * "}" 

-- The grammar

local TEMPLATE, FACEDEF, FACEUSE, CONTENT = lpeg.V'TEMPLATE', lpeg.V'FACEDEF', lpeg.V'FACEUSE', lpeg.V'CONTENT' 


local TEMPLATE=lpeg.P{
	TEMPLATE,
--[[
	-- I could not make this work -- help, anyone?
	FACEDEF = lpeg.P(function (s, i) -- function to make the multiple brackets syntax 
		local bb = lpeg.match(FACEDEFSTART, s)
		local bp = lpeg.match(OPENBRACKETS, s, bb)
		if bp then
			local endbracketslen = bp-bb
			local p = lpeg.P(string.rep(']', endbracketslen) .. '}' )
			p = (1 - p)^0 * p
			return lpeg.match(p, s, bp)
		end
		return false
	end),
]]	
	TEMPLATE=SPACE * (FACEDEF + CONTENT)^0,
	FACEDEF = (FACEDEFSTART / faceopen * (lpeg.Cp() * lpeg.C(CONTENT)) / facecontent * FACEDEFEND / faceclose) ,
	FACEUSE = PARAMFACEUSE + SIMPLEFACEUSE,
	CONTENT = (FACEDEF + FACEUSE / faceuse + SPECIALFUNCTION / special  + (1 - (FACEDEFSTART + FACEDEFEND)) )^1 * SPACE,
}

s = [===[

${a}

${@context[a.b.c]} 
${d[
	isso é um teste, 
	de um jeito ${e}
	bem legal

]} 

[=[ sss ]=] 

${@context[x]} 

${y[
	isso é um outro teste, 
	de um jeito 
	bem legal
	${z[
	Com mais um tipo de coisa
	]}
]}

a
${y{z=1}} -- not working
${y}




]===]

print(lpeg.match(TEMPLATE, s))

print_r(faces)