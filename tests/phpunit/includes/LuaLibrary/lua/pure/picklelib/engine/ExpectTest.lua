--- Tests for the expect module
-- This is a preliminary solution
-- @license GNU GPL v2+
-- @author John Erling Blad < jeblad@gmail.com >

local testframework = require 'Module:TestFramework'

local Expect = require 'picklelib/engine/Expect'
local expects = require('picklelib/Stack')

local function makeExpect( ... )
	return Expect.create( ... ):setExpects( expects.create() )
end

local function testExists()
	return type( Expect )
end

local function testCreate( ... )
	return type( makeExpect( ... ) )
end

local function testExpects( ... )
	local obj = makeExpect()
	local t = { ... }
	for _,v in ipairs( t ) do
		obj:expects():push( v )
	end
	return { obj:expects():export() }
end

local function testDoubleCall( ... )
	Expect( 'foo' )
	local obj = Expect( ... )
	Expect.stack:flush()
	return obj:temporal()
end

local tests = {
	{
		name = 'expect exists',
		func = testExists,
		type = 'ToString',
		expect = { 'table' }
	},
	{
		name = 'expect.create (nil value type)',
		func = testCreate,
		type = 'ToString',
		args = { nil },
		expect = { 'table' }
	},
	{
		name = 'expect.create (single value type)',
		func = testCreate,
		type = 'ToString',
		args = { 'a' },
		expect = { 'table' }
	},
	{
		name = 'expect.create (multiple value type)',
		func = testCreate,
		type = 'ToString',
		args = { 'a', 'b', 'c' },
		expect = { 'table' }
	},
	{
		name = 'expect.expects (multiple value)',
		func = testExpects,
		args = { 'a', 'b', 'c' },
		expect = { { 'a', 'b', 'c' } }
	},
	{
		name = 'expect.call (nil value)',
		func = testDoubleCall,
		args = {},
		expect = { 'foo' }
	},
	{
		name = 'expect.call (single value)',
		func = testDoubleCall,
		args = { 'a' },
		expect = { 'a' }
	},
	{
		name = 'expect.call (multiple value)',
		func = testDoubleCall,
		args = { 'a', 'b', 'c' },
		expect = { 'a', 'b', 'c' }
	},
}

return testframework.getTestProvider( tests )
