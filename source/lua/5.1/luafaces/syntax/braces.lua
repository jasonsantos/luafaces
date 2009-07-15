pcall(require,'luarocks.require')
module(..., package.seeall)

local lpeg = require'lpeg'

local tools = require "util"

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

onfacedef = function(this, facename, dependencies, templatetable)
	error'uninitialized face declaration event'
end

onfaceuse = function(facename, parameters)
	error'uninitialized face use event'
end

onfacerender = function(this, facename, templatetable, data)
	error'uninitialized face render event'
end

onparsespecial = function(context, functionname)
	error'uninitialized face render event'
end

onerror = function(context, functionname)
	error'error during parsing'
end

-- internal parser
-- -----------------------


local T_FACEDEF = {'face definition'}
local T_FACEUSE = {'face use'}
local T_FACEFUNC = {'face special function'}

local P, R, C, Ct, Cg, Cc, Cb, V, S = lpeg.P, lpeg.R, lpeg.C, lpeg.Ct, lpeg.Cg, lpeg.Cc, lpeg.Cb, lpeg.V, lpeg.S


-- Tokens

local WHITESPACE = S'\f \t\r\n'

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

-- Braces Syntax

local BRACES_SIMPLEUSE = P"${" * Cg(FACEUSENAME, 'tagname') * "}"
local BRACES_OPENTAGDEF = P"${" * Cg(FACENAME, 'tagname') * "["
local BRACES_CLOSETAGDEF = P']}'

local BRACES_SPECIALFUNCTION = P"${" * "@" * Cg(NAME, 'function') * "[" * Cg(FACEUSENAME, 'parameter') * "]" * "}" 

-- Braces: Face Use Parameters

local SPACE = (WHITESPACE^0)

local STRING = (lpeg.P'"' * ( (lpeg.P'\\' * 1) + (1 - (lpeg.S'"\n\r\f')) )^0 * lpeg.P'"') +
  (lpeg.P"'" * ( (lpeg.P'\\' * 1) + (1 - (lpeg.S"'\n\r\f")) )^0 * lpeg.P"'")

local LITERAL = SPACE * STRING * SPACE + SPACE * NUMBER * SPACE 

local ATTR = SPACE * Cg(FACEUSENAME, 'name') * SPACE * "=" * SPACE * Cg(LITERAL, 'value') * SPACE

local ARGUMENT = Ct(ATTR) + C(LITERAL)

local PARAMS = ARGUMENT * ("," * ARGUMENT)^0 

local PARAMFACEUSE = P"${" * Cg(FACEUSENAME, 'tagname') * "{" * Cg(Ct(PARAMS), 'parameters') * "}" * "}" 


local BRACES_TEXT = C((1-(BRACES_SIMPLEUSE + BRACES_OPENTAGDEF + BRACES_CLOSETAGDEF + PARAMFACEUSE + BRACES_SPECIALFUNCTION))^1)

-- Grammar
	
local CONTENT, FACEUSE, FACEDEF, FACEFUNC, BRACES_FACEDEF =  V'CONTENT', V'FACEUSE', V'FACEDEF', V'FACEFUNC', V'BRACES_FACEDEF'

local TEMPLATE = P{ CONTENT;
	CONTENT = (FACEFUNC + FACEDEF + FACEUSE + BRACES_TEXT)^1,
	FACEDEF = Ct(Cc(T_FACEDEF) * BRACES_FACEDEF),
	FACEFUNC = Ct(Cc(T_FACEFUNC) * BRACES_SPECIALFUNCTION),
	FACEUSE = Ct(Cc(T_FACEUSE) * (BRACES_SIMPLEUSE + PARAMFACEUSE)),
	BRACES_FACEDEF = BRACES_OPENTAGDEF * CONTENT * BRACES_CLOSETAGDEF,
}

local function event(name)
	local eventname = 'on'..tostring(name)
	return function(opt)
		if type(opt)=='function' then
			_G[eventname] = opt
		elseif type(opt)=='table' then
			_G[eventname] = opt[1]
		elseif type(opt)=='string' then
			_G[eventname] = loadstring(fn)
		end
	end
end

local function fire(name, ...)
	local eventname = 'on'..tostring(name)
	return _G[eventname](name, ...)
end

function createcontext(context, facename)
	local ctx = {}
	if type(context)=='string' then
		context = string.split(context,'.')
	end
	 
	if string.sub(facename, 1, 1)=='_' then
		facename = string.sub(facename, 2)
	else
		table.add(ctx, context or {})
	end
	table.add(ctx, string.split(facename,'.'))
	return ctx
end

local function build(context, t)
	if not t then
		fire('error', context, 'Invalid face definition')
	elseif type(t)~='table' then print('string')
		return 'faceuse', t
	elseif t[1]==T_FACEDEF then print('def')
		local ctx =  createcontext(context, t.tagname) 
		local res = {this=ctx, name=ctx[#ctx], decl={}, deps={}, tpl={}}
		for i=2, #t do
			local o=t[i]
			
			local kind, faceref = build(ctx, o)

			if kind=='facedef' then
				local name = table.concat(faceref,'.')
				res.decl[name] = faceref
				kind='faceuse'
			end
			if kind=='faceuse' then
				if type(faceref)=='table' then
					local name = table.concat(faceref,'.')
					if not res.decl[name] then
						res.deps[name] = faceref 
					end
				end
				table.insert(res.tpl, faceref)
			end
			
		end
		return 'facedef', fire('facedef', res.this, res.name, res.decl, res.deps, res.tpl)
	elseif t[1]==T_FACEUSE then print('use')
		local ctx = createcontext(context, t.tagname) 
		return 'faceuse', fire('faceuse', ctx, t.parameters)
	elseif t[1]==T_FACEFUNC then
		return '_', fire('parsespecial', context, t['function'], t.parameter)
	end
end

function parse(options)
	local context = options.context or {}
	local facename = options.faceName
	local content = options.content
	
	local result = {tagname=facename, TEMPLATE:match(content)}
	
	table.insert(result, 1, T_FACEDEF)
	
	event'facedef' {
		options.onFaceDefinition or function(e, ctx, name, decl, deps, tpl)
			return ctx
		end
	} 
	
	event'faceuse'{
		options.onFaceUse or function(e, ctx, params)
			return ctx
		end
	} 
	
	event'facerender'{
		options.onFaceRender or function(e, ctx, tpl, params)
			return {ctx, tpl, params}
		end
	} 
	
	event'parsespecial'{
		options.onParseSpecial or function(e, ctx, fn, param)
			return {ctx, fn, param}
		end
	} 

	return build(context, result)
end
--[=[
parse{
	faceName='Main',
	content = [[

${@context[a.b.c]} 
${a}

${d[
	isso é um teste, 
	de um jeito ${e}
	bem legal

]} 


${@context[x]} 

${y[
	isso é um outro teste, ${e}
	de um jeito 
	bem legal
	
	${ze.yps[
	Com mais um tipo de coisa
		${x[
			dentro demais ${corredor}
		]}

		${@context[celenterado]} 
		
		${x[
			dentro demais ${corredor}
		]}
	
		${wa.xi[
			 Ultimate ${test}
		]}

		${_wa.xi[
			 Ultimate ${test}
		]}

	]}
]}

a
${y{z=1}}
${y{a=324,b=234,z=1}}
${y{1, 2, 3, 4, g=12}}
${y{name="peteca no \nchão"}}

${@context[a.b.c]} 
${a}

${d[
	isso é um teste, 
	de um jeito ${e}
	bem legal

]} 

]]

}
]=]--