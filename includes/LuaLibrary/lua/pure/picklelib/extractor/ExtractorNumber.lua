--- Subclass to do specialization of the extractor strategy class.
-- This spesialization do casting into a number type.
-- This class follows the pattern with inheritance from
-- [Lua classes](../topics/lua-classes.md.html).
-- @classmod ExtractorNumber
-- @alias Subclass

-- pure libs
local libUtil = require 'libraryUtil'
local Super = require 'picklelib/extractor/Extractor'

-- @var class var for lib
local Subclass = {}

--- Lookup of missing class members.
-- @raise on wrong arguments
-- @tparam string key lookup of member
-- @return any
function Subclass:__index( key ) -- luacheck: no self
	libUtil.checkType( 'ExtractorNumber:__index', 1, key, 'string', false )
	return Subclass[key]
end

-- @var metatable for the class
setmetatable( Subclass, { __index = Super } )

--- Create a new instance.
-- @tparam vararg ... forwarded to @{Extractor:create|superclass create method}
-- @treturn self
function Subclass:create( ... )
	return Super.create( self or Subclass, ... )
end

--- Initialize a new instance.
-- @treturn self
function Subclass:_init()
	Super._init( self,
		{ '^[-+]?%d+%.%d+$', 0, 0 },
		{ '^[-+]?%d+%.%d+[%s%p]', 0, -1 },
		{ '[%s%p][-+]?%d+%.%d+$', 1, 0 },
		{ '[%s%p][-+]?%d+%.%d+[%s%p]', 1, -1 },
		{ '^[-+]?%d+$', 0, 0 },
		{ '^[-+]?%d+[%s%p]', 0, -1 },
		{ '[%s%p][-+]?%d+$', 1, 0 },
		{ '[%s%p][-+]?%d+[%s%p]', 1, -1 } )
	self._type = 'number'
	return self
end

--- Cast the string into the correct type for this strategy.
-- There are no safeguards for erroneous casts.
-- @see Extractor:cast
-- @raise on wrong arguments
-- @tparam string str used as the extraction source
-- @tparam number start for an inclusive index where extraction starts
-- @tparam number finish for an inclusive index where extraction finishes
-- @treturn number
function Subclass:cast( str, start, finish )
	libUtil.checkType( 'ExtractorNumber:cast', 1, str, 'string', false )
	libUtil.checkType( 'ExtractorNumber:cast', 2, start, 'number', false )
	libUtil.checkType( 'ExtractorNumber:cast', 3, finish, 'number', false )

	if not finish then
		start, finish = self:find( str, (start or 1) )
	end
	return tonumber( mw.ustring.sub( str, start, finish ) )
end

--- Get the placeholder for this strategy.
-- @treturn string
function Subclass:placeholder() -- luacheck: no self
	return 'number'
end

-- Return the final class.
return Subclass
