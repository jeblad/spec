--- Tests for the extractor strategies module.
-- This is a preliminary solution.
-- @license GPL-2.0-or-later
-- @author John Erling Blad < jeblad@gmail.com >


local testframework = require 'Module:TestFramework'

local name = 'extractor'

local function makeTest( ... )
	local lib = require 'picklelib/extractor/Extractors'
	assert( lib )
	return lib:create( ... )
end

local function testExists()
	return type( makeTest() )
end

local function testCreate( ... )
	return type( makeTest( ... ) )
end

local function testNumFlush( ... )
	local obj = makeTest( ... )
	local t = { obj:num() }
	obj:flush()
	table.insert( t, obj:num() )
	return unpack( t )
end

local function testFind( str, ... )
	local t = { makeTest( ... ):find( str, 1 ) }
	local obj = table.remove( t, 1 )
	table.insert( t, obj:getType() )
	return unpack( t )
end

local tests = {
	{ -- 1
		name = name .. ' exists',
		func = testExists,
		type = 'ToString',
		expect = { 'table' }
	},
	{ -- 2
		name = name .. ':create (nil value type)',
		func = testCreate,
		type = 'ToString',
		args = { nil },
		expect = { 'table' }
	},
	{ -- 3
		name = name .. ':create (single value type)',
		func = testCreate,
		type = 'ToString',
		args = { require 'picklelib/extractor/ExtractorNil' },
		expect = { 'table' }
	},
	{ -- 5
		name = name .. ':create (single value type)',
		func = testCreate,
		type = 'ToString',
		args = { require 'picklelib/extractor/ExtractorTrue' },
		expect = { 'table' }
	},
	{ -- 8
		name = name .. ':num-flush (no value)',
		func = testNumFlush,
		args = {},
		expect = { 0, 0 }
	},
	{ -- 9
		name = name .. ':num-flush (single value)',
		func = testNumFlush,
		args = { { 'foo' } },
		expect = { 1, 0 }
	},
	{ -- 10
		name = name .. ':num-flush (multiple value)',
		func = testNumFlush,
		args = { { 'foo' }, { 'bar' }, { 'baz' } },
		expect = { 3, 0 }
	},
	{ -- 11
		name = name .. ':find (nil extract)',
		func = testFind,
		args = { 'foo nil bar', require('picklelib/extractor/ExtractorNil'):create() },
		expect = { 5, 7, 'nil' }
	},
	{ -- 13
		name = name .. ':find (true extract)',
		func = testFind,
		args = { 'foo true bar', require('picklelib/extractor/ExtractorTrue'):create() },
		expect = { 5, 8, 'true' }
	},
}

return testframework.getTestProvider( tests )
