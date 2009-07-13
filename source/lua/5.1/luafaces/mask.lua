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


local build

local function defineMask(maskstub, definition)
	if type(maskstub)~= 'table' or not maskstub['.faceName'] or not definition then
		error('Invalid face definition', 2)
	end
table.foreach(maskstub, print)
	local faceName = maskstub['.faceName']
print(faceName)
	local face = mold.repository[faceName]
	if face then
		mold.unregister(faceName)
	end
	
	if type(definition)=='string' then
		definition = build(faceName, definition)
	end
	
	return mold.register(faceName, definition)
end

function define(facename)
	return setmetatable( {['.prototype']='face', ['.faceName']=facename }, { __call=defineMask })
end

build=function(facename, facedefinition)

	local face_mt = {
		__index=function(o, idx)
			local f = mold.find(o)
			return rawget(f,idx)
		end
	}

	local options = {
		faceName= facename,
		content = facedefinition,
		
		onFaceDefinition = function(e, ctx, name, decl, deps, tpl)
		print('>',e, unpack(ctx))
			local faceName = table.concat(ctx, '.')
			mold.register(faceName, {
				['.prototype']	= 'face', 
				['.faceName']	= faceName,
				declarations 	= decl,
				dependencies 	= deps,
				template 		= tpl,
				attributes 		= {},
				render = function(data)
					for _, item in ipairs(tpl) do
						
					end
				end 
			})
			return setmetatable({unpack(ctx)}, face_mt)
		end,
		
		onFaceUse = function(e, ctx, parameters)
			-- TODO: unpack/compile parameters
			print(e, ctx)
			return {unpack(ctx), parameters=parameters}
		end,
		
		onFaceRender = function(e, ctx, tpl, params)
			
		end,
		
		onParseSpecial = function(e, ctx, fn, param)
		print(e, ctx)
			if fn=='context' then
				table.replace(ctx, string.split(param, '.'))
			end		
		end,
	}
	
	local type, facedef = braces.parse(options)
	return facedef
end 

function compile(template, t, r)
	local txtTable = t or {}
	local refTable = r or {}

	for _init, str, _end in string.gmatch(template, "(%$?%{?)([^%$%{.-%}]+)(%}?)") do
		if (_init == "${" and _end == "}") then
			refTable[str] = refTable[str] or {}
			table.insert(refTable[str], #txtTable+1)
			_init = ''
			str = ''
			_end = ''
		end
		table.insert(txtTable, _init)
		table.insert(txtTable, str)
		table.insert(txtTable, _end)
	end
	return {source=template, serial=txtTable, references=refTable}
end

function render(tt,data, ...)
	local t, r = tt.serial, tt.references

	local t_text = table.clone(t)

	for key, positions in pairs(r) do
		-- TODO: treat the 'only from data' and 'only from faces' trigger
		if data and data[key] then
			for _, pos in ipairs(positions) do
				local content = data[key]
				if type(content)=='function' then
					t_text[pos] = content(...) 
				elseif type(content)=='table' then -- data[key] is a table
					-- TODO: repeat the pattern
				else 
					t_text[pos] = tostring(content)
				end
			end
		end
	end
	return table.concat(t_text)
end