local mold = require'luafaces.mold'

assert(mold)

mold.register('br.com.fabricadigital.*.app.newsletter', "XPTO")

local t=os.clock()
for i=1,1000000 do
	a = mold.find'br.com.fabricadigital.commercial.app.newsletter'
end
print(os.clock()-t)
print(a)
mold.dump()

mold.register('br.com.fabricadigital.*.app.newsletter')

a = mold.find'br.com.fabricadigital.commercial.app.newsletter'
print(a)
mold.dump()


print'OK'