module(..., package.seeall)

--[[

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




]]---


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


-- internal parser
-- -----------------------


-- Tokens

local WHITESPACE = (lpeg.S'\n \t\r\f')^0

local NAMESTARTCHAR	= lpeg.R"A-Z" + "_" + lpeg.R"a-z"
local NAMECHAR	= NAMESTARTCHAR + "." + lpeg.R"0-9"



-- variables
-- --------------

context = {}
stack = {}

