--- Intermediate class for frame report renderer.
-- This class follows the pattern from [Lua classes](../topics/lua-classes.md.html).
-- @classmod RenderFrame
-- @alias Subclass

-- @var super class
local Super = require 'picklelib/render/Render'

-- @var intermediate class
local Subclass = {}

--- Lookup of missing class members.
-- @tparam string key used for lookup of member
-- @return any
function Subclass:__index( key ) -- luacheck: no self
	return Subclass[key]
end

-- @var metatable for the class
setmetatable( Subclass, { __index = Super } )

--- Create a new instance.
-- @see Render:create
-- @tparam vararg ... forwarded to @{Render:create}
-- @treturn self
function Subclass:create( ... )
	return Super.create( self, ... )
end

--- Initialize a new instance.
-- @local
-- @tparam vararg ... forwarded to @{Render:_init}
-- @return self
function Subclass:_init( ... )
	Super._init( self, ... )
	self._type = 'render-frame'
	return self
end

--- Override key construction.
-- @tparam string str to be appended to a base string
-- @treturn string
function Subclass:key( str )
	return 'pickle-report-frame-' .. self:cleanKey( str )
end

--- Realize reported data for state.
-- @tparam Report src that shall be realized
-- @tparam[opt] string lang code used for realization
-- @tparam[opt] Counter counter holding the running count
-- @treturn string
function Subclass:realizeState( src, lang, counter )
	assert( src, 'Failed to provide a source' )

	return self:realizeClarification( src:isOk() and 'is-ok' or 'is-not-ok', lang, counter )
end

--- Realize reported data for skip.
-- The "skip" is a message identified by a key.
-- @tparam Report src that shall be realized
-- @tparam[opt] string lang code used for realization
-- @treturn string
function Subclass:realizeSkip( src, lang )
	assert( src, 'Failed to provide a source' )

	return self:realizeComment( src, 'skip', lang )
end

--- Realize reported data for todo.
-- The "todo" is a text string.
-- @tparam Report src that shall be realized
-- @tparam[opt] string lang code used for realization
-- @treturn string
function Subclass:realizeTodo( src, lang )
	assert( src, 'Failed to provide a source' )

	return self:realizeComment( src, 'todo', lang )
end

--- Realize reported data for description.
-- The "description" is a text string.
-- @tparam Report src that shall be realized
-- @tparam[opt] string lang code used for realization
-- @treturn string
function Subclass:realizeDescription( src, lang ) -- luacheck: no unused args
	assert( src, 'Failed to provide a source' )

	if not src:hasDescription() then
		return ''
	end

	return mw.text.encode( src:getDescription() )
end

--- Realize reported data for header.
-- The "header" is a composite.
-- @tparam Report src that shall be realized
-- @tparam[opt] string lang code used for realization
-- @tparam[opt] Counter counter holding the running count
-- @treturn string
function Subclass:realizeHeader( src, lang, counter )
	assert( src, 'Failed to provide a source' )

	local t = { self:realizeState( src, lang, counter ) }

	if src:hasDescription() then
		table.insert( t, self:realizeDescription( src, lang ) )
	end

	if src:isSkip() or src:hasSkip() or src:isTodo() or src:hasTodo() then
		table.insert( t, '#' )
	end

	if src:isSkip() or src:hasSkip() then
		table.insert( t, self:realizeSkip( src, lang ) )
	end

	if src:isTodo() or src:hasTodo() then
		table.insert( t, self:realizeTodo( src, lang ) )
	end

	return table.concat( t, ' ' )
end

--- Realize reported data for body.
-- The "body" is a composite.
-- @tparam Report src that shall be realized
-- @tparam[opt] string lang code used for realization
-- @treturn string
function Subclass:realizeBody( src, lang ) -- luacheck: ignore self lang
	assert( src, 'Failed to provide a source' )

	local t = {}

--[[
	for _,v in ipairs( { src:constituents():export() } ) do
		table.insert( t, self:realize( v, lang ) )
	end
]]
	return #t == 0 and '' or ( "\n" .. table.concat( t, "\n" ) )
end

-- Return the final class.
return Subclass
