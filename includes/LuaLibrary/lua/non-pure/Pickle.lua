--- Register functions for the testing framework.
-- @module Pickle

-- accesspoints for the boilerplate
local php		-- luacheck: ignore
local options	-- luacheck: ignore

-- pure libs
local libUtil = require 'libraryUtil'

-- @var structure for storage of the lib
local pickle = {}

pickle.bag = require 'picklelib/Bag'
pickle.counter = require 'picklelib/Counter'
pickle.spy = require 'picklelib/engine/Spy'
pickle.frame = require 'picklelib/engine/Frame'
pickle.adapt = require 'picklelib/engine/Adapt'
pickle.double = require 'picklelib/engine/Double'
pickle.report = {}
pickle.report.adapt = require 'picklelib/report/ReportAdapt'
pickle.report.frame = require 'picklelib/report/ReportFrame'
pickle.renders = require 'picklelib/render/Renders'
pickle.extractors = require 'picklelib/extractor/Extractors'
pickle.translator = require 'picklelib/translator/Translator'
pickle.translators = require 'picklelib/translator/Translators'

--- Add further options for translators
-- @tparam table opts
local function addTranslatorOptions( opts )
	if opts.translationPage then
		opts.langCode = opts.langCode
			or (options.translationFollows == 'content' and options.contLang)
			or (options.translationFollows == 'user' and options.userLang)
	else
		if opts.langCode then
			opts.translationPage = string.format( options.translationPath.user,
				mw.title.getCurrentTitle().text,
				opts.langCode )
		elseif options.translationFollows == 'content' then
			opts.translationPage = string.format( options.translationPath.content,
				mw.title.getCurrentTitle().text,
				options.contLang )
			opts.langCode = options.contLang
		-- this variant only works properly if caching is turned off
		elseif options.translationFollows == 'user' then
			opts.translationPage = string.format( options.translationPath.user,
				mw.title.getCurrentTitle().text,
				options.userLang )
			opts.langCode = options.userLang
		else
			opts.translationPage = false
		end
	end
end

--- Create translators
-- @tparam table opts
-- @treturn Translators
local function createTranslators( opts )
	local translators = pickle.translators:create()

	if not opts.translationPage then
		return nil
	end

	local translationData = nil
	if opts.translationPage then
		pcall( function()
			translationData = mw.loadData( opts.translationPage )
		end )
	end

	for k,v in pairs( translationData or {} ) do
		-- skips metadata
		if not string.match( k, '^@' ) then
			translators:register( k, pickle.translator:create( v ) )
		end
	end

	return translators
end

--- Add further options for extractors
-- @tparam table opts
local function addExtractorOptions( opts )
	if opts.extractorLibs then
		return
	end

	opts.extractorLibs = {}
	for k,v in pairs( options.extractors or {} ) do
		local lib = string.format( options.extractorPath, v )
		table.insert( opts.extractorLibs, { k, lib } )
	end
end

--- Create extractors
-- @tparam table opts
-- @treturn Extractors
local function createExtractors( opts )
	local extractors = pickle.extractors:create()

	for _,v in ipairs( opts.extractorLibs or {} ) do
		extractors:register( require( v[2] ):create() )
	end

	return extractors
end

--- Add further options for renders
-- @tparam table opts
local function addRenderOptions( opts )
	if opts.renderLibs then
		return
	end

	opts.renderLibs = {}
	for k,v in pairs( options.renderStyles ) do
		for l,w in pairs( options.renderTypes ) do
			local lib = string.format( options.renderPath, k, w, v )
			table.insert( opts.renderLibs, { k, l, lib } )
		end
	end
end

--- Create Renders
-- @tparam table opts
-- @treturn Renders
local function createRenders( opts )
	local renders = pickle.renders
	for _,v in ipairs( opts.renderLibs ) do
		local style = renders.registerStyle( v[1] )
		assert( style )
		style:registerType( v[2], require( v[3] ) )
	end

	return renders
end

-- Setup framework.
-- This needs a valid environment, for example from getfenv()
-- @tparam table env
-- @tparam table opts
-- @treturn table environment
local function setup( env, opts )
	libUtil.checkType( 'setup', 1, env, 'table', false )
	libUtil.checkType( 'setup', 2, opts, 'table', true )

	opts = opts or {}

	addTranslatorOptions( opts )
	local translators = createTranslators( opts )

	addExtractorOptions( opts )
	local extractors = createExtractors( opts )

	addRenderOptions( opts )
	local renders = createRenders( opts )

	local reports = pickle.bag:create()
	local frames = pickle.bag:create()
	local expects = pickle.bag:create()
	local subjects = pickle.bag:create()

	--- Make a test double
	-- This is for mimickin general behavior, and acts like it is a function.
	-- Returns precomputed values or compute them on the fly.
	-- @function stub
	-- @tparam table|string|boolean|number|function ... arguments to be parsed
	-- @treturn function
	env.stub = function( ... )
		return pickle.double:create():setLevel(2):setName('stub'):dispatch( ... ):stub()
	end

	--- Make a carp on the current report.
	-- This is usualy called due to debugging a possible error condition.
	-- Prints a “todo” comment, caller's name and arguments.
	-- @function carp
	-- @tparam nil|string str message to use for todo part of report
	-- @return Spy
	env.carp = function( str )
		libUtil.checkType( 'carp', 1, str, 'string', true )
		str = str or mw.message.new( 'pickle-spies-carp-todo' ):plain()
		return pickle.spy:create():setReports( reports ):doCarp( str )
	end

	--- Make a cluck on the current report.
	-- This is usually called due to debugging a possible error condition.
	-- Prints a “todo” comment, caller's name and arguments, and a stack backtrace.
	-- @function cluck
	-- @tparam nil|string str message to use for todo part of report
	-- @return Spy
	env.cluck = function( str )
		libUtil.checkType( 'cluck', 1, str, 'string', true )
		str = str or mw.message.new( 'pickle-spies-cluck-todo' ):plain()
		return pickle.spy:create():setReports( reports ):doCluck( str )
	end

	--- Make a croak on the current report.
	-- This is usually called due to debugging a possible error condition.
	-- Prints a “skip” comment, caller's name and arguments, and exits.
	-- @function croak
	-- @raise unconditionally
	-- @tparam nil|string str message to use for todo part of report
	-- @tparam[opt=0] nil|number level to report
	env.croak = function( str, level )
		libUtil.checkType( 'croak', 1, str, 'string', true )
		libUtil.checkType( 'croak', 2, level, 'number', true )
		str = str or mw.message.new( 'pickle-spies-croak-skip' ):plain()
		pickle.spy:create():setReports( reports ):doCroak( str )
		error( mw.message.new( 'pickle-spies-croak-exits' ):plain(), level or 0 )
	end

	--- Make a confess(ion) on the current report.
	-- This is usually called due to debugging a possible error condition.
	-- Prints a “skip” comment, caller's name and arguments, a stack backtrace, and exits.
	-- @function confess
	-- @raise unconditionally
	-- @tparam nil|string str message to use for todo part of report
	-- @tparam[opt=0] nil|number level to report
	env.confess = function( str, level )
		libUtil.checkType( 'confess', 1, str, 'string', true )
		libUtil.checkType( 'croak', 2, level, 'number', true )
		str = str or mw.message.new( 'pickle-spies-confess-skip' ):plain()
		pickle.spy:create():setReports( reports ):doConfess( str )
		error( mw.message.new( 'pickle-spies-confess-exits' ):plain(), level or 0 )
	end

	--- Make a skip comment on the current report.
	-- This function will not terminate the current run.
	-- Consider @{Pickle.croak|croak} or @{Pickle.confess|confess}.
	-- @function skip
	-- @tparam nil|string str message to be passed on
	env.skip = function( str )
		libUtil.checkType( 'skip', 1, str, 'string', true )
		reports:top():setSkip( str
			or mw.message.new( 'pickle-report-frame-skip-no-description' ):plain() )
	end

	--- Make a todo comment on the current report.
	-- This function will not terminate the current run.
	-- Consider @{Pickle.carp|carp} or @{Pickle.cluck|cluck}.
	-- @function todo
	-- @tparam nil|string str message to be passed on
	env.todo = function( str )
		libUtil.checkType( 'todo', 1, str, 'string', true )
		reports:top():setTodo( str
			or mw.message.new( 'pickle-report-frame-todo-no-description' ):plain() )
	end

	--- Expect whatever to be compared to the subject.
	-- The expected value is the assumed outcome,
	-- or something that can be transformed into the
	-- assumed outcome.
	-- @function expect
	-- @param ... varargs passed on to Adapt:create
	-- @return Adapt
	env.expect = function( ... )
		local obj = pickle.adapt:create( ... )
			:setReports( reports )
			:setAdaptations( expects )
		return obj
	end

	--- Subject of whatever to be compared to the expected.
	-- The subject is whatever object we want to test,
	-- usually the returned table for a module.
	-- @function subject
	-- @param ... varargs passed on to Adapt:create
	-- @return Adapt
	env.subject = function( ... )
		local obj = pickle.adapt:create( ... )
			:setReports( reports )
			:setSubjects( subjects )
		return obj
	end

	--- Helper to get the named style
	-- @param frame
	-- @treturn string
	local function findStyle( frame )
		if frame.args.style then
			return frame.args.style
		end
		local names ={}
		for _,v in ipairs( opts.renderLibs ) do
			names[v[1]] = true
		end
		for _,v in ipairs( frame.args ) do
			if names[v] then
				return v
			end
		end
		return nil
	end

	--- Helper to get the identified language
	-- @param frame
	-- @treturn string
	local function findLang( frame )
		if frame.args.lang then
			return frame.args.lang
		end
		for _,v in ipairs( frame.args ) do
			if mw.language.isValidCode( v ) then
				return v
			end
		end
		return nil
	end

	--- Silent “describe” for the test.
	-- This is the outermost of the three levels.
	-- The function will silently avoid running the fixture.
	-- @function xdescribe
	-- @param ... varargs passed on to Frame:dispatch
	-- @return Frame
	env.xdescribe = function( ... )
		local obj = pickle.frame:create()
		frames:unshift( obj )
		obj.evalFixture = function( this )
			local ReportFrame = require 'picklelib/report/ReportFrame'
			local msg = mw.message.new( 'pickle-adapt-silent' )
			this:reports():push( ReportFrame:create():setSkip( msg ) )
		end
		obj:setRenders( pickle.renders )
			:setName( 'xdescription' )
			:setReports( reports )
			:setSubjects( subjects )
			:setExtractors( extractors )
			:setTranslators( translators )
			:dispatch( ... )
		return obj
	end

	--- Silent “context” for the test.
	-- This is usually used for creating some additional context
	-- before the actual testing.
	-- The function will silently avoid running the fixture.
	-- @function context
	-- @param ... varargs passed on to Frame:dispatch
	-- @return Frame
	env.xcontext = function( ... )
		local obj = pickle.frame:create()
		obj.evalFixture = function( this )
			local ReportFrame = require 'picklelib/report/ReportFrame'
			local msg = mw.message.new( 'pickle-adapt-silent' )
			this:reports():push( ReportFrame:create():setSkip( msg ) )
		end
		obj:setRenders( pickle.renders )
			:setName( 'xcontext' )
			:setReports( reports )
			:setSubjects( subjects )
			:setExtractors( extractors )
			:setTranslators( translators )
			:dispatch( ... )
		return obj
	end

	--- Silent “it” for the test.
	-- @tparam vararg ... passed on to Frame:create
	-- @treturn self newly created object
	env.xit =function( ... )
		local obj = pickle.frame:create()
		obj.evalFixture = function( this )
			local ReportFrame = require 'picklelib/report/ReportFrame'
			local msg = mw.message.new( 'pickle-adapt-silent' )
			this:reports():push( ReportFrame:create():setSkip( msg ) )
		end
		obj:setRenders( pickle.renders )
			:setName( 'xit' )
			:setReports( reports )
			:setSubjects( subjects )
			:setExtractors( extractors )
			:setTranslators( translators )
			:dispatch( ... )
		return obj
	end

	--- “Describe” for the test.
	-- This is the outermost of the three levels.
	-- @function describe
	-- @param ... varargs passed on to Frame:dispatch
	-- @return Frame
	env.describe = function( ... )
		local obj = pickle.frame:create()
		frames:unshift( obj )
		obj:setRenders( pickle.renders )
			:setName( 'describe' )
			:setReports( reports )
			:setSubjects( subjects )
			:setExtractors( extractors )
			:setTranslators( translators )
			:dispatch( ... )

		--- Eval the fixtures over previous dispatched strings.
		-- This is extending the `describe` call by injecting `tap` as an method.
		-- The method has two different call forms. First form is the usual one with a single
		-- frame object. This is used if the function is called by "invoke". The second
		-- form use the same "style" and "language" form, but as arguments. This makes
		-- it possible to easilly test it in the console.
		-- @return string
		function obj:tap( ... )
			self:eval()
			assert( reports:top(), 'Pickle: Can not find top')

			local styleName = nil
			local langCode = nil

			if select( '#', ... ) == 1 and type( select( 1, ... ) ) == 'table'  then
				local frame = select( 1, ... )
				styleName = findStyle( frame )
				langCode = findLang( frame )

			elseif select( '#', ... ) > 1 then
				local frame = { args = { style = select( 1, ... ), lang = select( 2, ... ) } }
				styleName = findStyle( frame )
				langCode = findLang( frame )
			end

			styleName = styleName or 'full'
			langCode = langCode or mw.language.getContentLanguage():getCode()

			local style = renders.style( styleName )
			return reports:top():realize( style, langCode, pickle.counter:create() )
		end

		return obj
	end

	--- “Context” for the test.
	-- This is usually used for creating some additional context
	-- before the actual testing. An alternate would be to use
	-- 'before' and 'after' functions.
	-- @function context
	-- @param ... varargs passed on to Frame:dispatch
	-- @return Frame
	env.context = function( ... )
		local obj = pickle.frame:create()
			:setName( 'context' )
			:setReports( reports )
			:setSubjects( subjects )
			:setExtractors( extractors )
			:setTranslators( translators )
			:dispatch( ... )
		return obj
	end

	--- “It” for the test.
	-- @tparam vararg ... passed on to Frame:create
	-- @treturn self newly created object
	env.it = function( ... )
		local obj = pickle.frame:create()
			:setName( 'it' )
			:setReports( reports )
			:setSubjects( subjects )
			:setExtractors( extractors )
			:setTranslators( translators )
			:dispatch( ... )
		return obj
	end

	env.execute = function()
		for _,v in ipairs( { frames:export() } ) do
			v:eval()
		end
		local style = pickle.renders.style( 'vivid' )
		local code = mw.language.getContentLanguage():getCode()
		local counter = pickle.counter:create()
		return reports:realize( style, code, counter )
	end

	--- Put up a nice banner telling everyone pickle is initialized, and add the instances
	env._reports = reports
	env._renders = renders
	env._extractors = extractors
	env._translators = translators
	env._PICKLE = true

	return env
end

-- @var metatable for the library
local mt = { types = {} }

--- Install the library.
-- This install all dependencies and changes the environment
-- @function mw.pickle.__call
-- @tparam table opts for the options
-- @treturn self
function mt:__call( opts ) -- luacheck: no self
	libUtil.checkType( '__call', 1, opts, 'table', true )
	opts = opts or {}

	-- Get the environment for installation of our access points
	-- This is necessary for testing.
	local ret,env = pcall( function() return getfenv( 4 ) end )
	if not ret then
		env = _G
	end

	setup( env, opts )
end

setmetatable( pickle, mt )

--- install the module in the global space.
function pickle.setupInterface( opts )

	-- boilerplate
	pickle.setupInterface = nil
	php = mw_interface
	mw_interface = nil
	options = opts -- @todo move data from this more methodically

	-- register main lib
	mw = mw or {}
	mw.pickle = pickle
	package.loaded['mw.Pickle'] = pickle
	pickle._IMPLICIT = opts.setup == 'implicit'

end

-- Return the final library
return pickle
