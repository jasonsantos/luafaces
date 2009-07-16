pcall(require,'luarocks.require')
module(..., package.seeall)

local mold = require'luafaces.mold'
local braces = require "luafaces.syntax.braces"
local tags = require "luafaces.syntax.tags"

local tools = require "util"

--[==[--
A mask is a table
with a render function

This function, receives a table as a parameter
It has a list of needed variables in a parameter
Upon executing, this function must seek in this table a list of needed variables
and replace them, by index, in a copy of its template table

then, concatenate the table and return it.


a template can be rendered.


t = [[
	${name[Fulano de Tal]}

	${option[
		Fulano de Tal do tipo ${type}
	]}


	${name} renders the face called 'name'

	${option{type=1}} renders the face called option with a parameter 'type' with a value of 1
	]]

--]==]--


local facestub_mt = {
	__index=function(o, idx)
		local face = rawget(o, '.face')
		if not face then 
			face = mold.find(o)
			rawset(o, '.face', face)
		end
	
		return rawget(face or o,idx)
	end
}

local function faceDefHandler(e, ctx, name, decl, deps, tpl,renderfn)
	local faceName = table.concat(ctx, '.')

	mold.register(ctx, {
		['.prototype']	= 'face', 
		['.faceName']	= name,
		['.fullContext']= ctx,
		['.fullName']	= faceName,
		declarations 	= decl,
		dependencies 	= deps,
		template 		= tpl,
		attributes 		= {},
		render = renderfn or function(face, data, res, renderfn, context)
			local tpl = face.template or {}
			local r = res or {}
			for _, item in ipairs(tpl) do
				if item ~= face then
					if type(item)=='table' then
						local content = util.choose(data, item)
						--TODO: repeat the render with different data if the content is an array
						--TODO: replace the face template with the content if the content is a string
						if item.render then
							--TODO: use the data table
							--TODO: load facefiles
							local pos = #r
							local s = item:render(data, r, renderfn, context)
							if pos==#r and type(s)=='string' then
								table.insert(r, s)								
							end
						else
							table.insert(r, '')
						end
					else
						table.insert(r, tostring(item))
					end
				end
			end
			
			local result = not res and table.concat(r)
			
			if result and renderfn then
				result = renderfn(result, context)
			end
			
			return result 
		end 
	})
	return setmetatable({unpack(ctx)}, facestub_mt)
end

local function faceUseHandler(e, ctx, parameters)
	-- TODO: unpack/compile parameters
	local face = {unpack(ctx)}
	face.parameters=parameters
	return setmetatable(face, facestub_mt) 
end

local function parseSpecialHandler(e, ctx, fn, param)
	if fn=='context' then
		table.replace(ctx, string.split(param, '.'))
	end		
end

--- faz o parsing da face a partir da string de declaração
local function build(facename, facedefinition)

	local options = {
		faceName= facename,
		content = facedefinition,
		
		onFaceDefinition = faceDefHandler,
		onFaceUse = faceUseHandler,
		onParseSpecial = parseSpecialHandler,
	}
	
	local type, faceref = braces.parse(options)
	return faceref
end 

--- Efetiva a declaração da Face
local function defineMask(maskstub, definition)
	if type(maskstub)~= 'table' or not maskstub['.faceName'] or not definition then
		error('Invalid face definition', 2)
	end

	local faceName = maskstub['.faceName']

	if type(definition)=='string' then
		definition = build(faceName, definition)
	else
		local ctx, name = braces.createcontext(definition.context or {}, faceName)
		
		definition = faceDefHandler('facedef',ctx, name, definition.declarations,definition.dependencies,definition.template,definition.render)
	end
	
	return definition
end

--- define um stub de declaração de Face
function define(facename)
	return setmetatable( {['.prototype']='face', ['.faceName']=facename }, { __call=defineMask })
end

