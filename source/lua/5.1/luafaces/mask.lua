module('luafaces.mask', package.seeall)

local mold = require'luafaces.mold'
local braces = require "luafaces.syntax.braces"
local tags = require "luafaces.syntax.tags"

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
	${{name{Fulano de Tal}}}

	${{option{
		Fulano de Tal do tipo ${type}
	}}}


	${name} renders the face called 'name'

	${option{type=1}} renders the face called option with a parameter 'type' with a value of 1
	]]

--]==]--


local function defineMask(maskstub, definition)
	if type(maskstub)~= 'table' or not maskstub[1] then
		error('Invalid definition call', 2)
	end
	table.foreach(maskstub, print)
	local mask = maskstub[1]
print(mask)
	local face = mold.repository[mask]
	if face then
		mold.unregister(mask)
	end
	mold.register(mask, definition)
end

function define(maskname)
	return setmetatable( {maskname}, { __call=defineMask })
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

	local t_text = {} --copies the txtTable (is it really necessary?)
	for i, v in ipairs(t) do
		table.insert(t_text, v)
	end

	for key, var in pairs(r) do
		if data and data[key] then
			for _, pos in ipairs(r[key]) do
				local content = data[key]
				t_text[pos] = type(content)=='function' and  content(...) or content
			end
		end
	end
	return table.concat(t_text)
end