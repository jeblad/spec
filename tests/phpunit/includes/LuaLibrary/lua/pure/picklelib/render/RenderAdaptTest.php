<?php

namespace Pickle\Test;

use Scribunto_LuaEngineTestBase;

/**
 * @group Pickle
 *
 * @license GPL-2.0-or-later
 *
 * @author John Erling Blad < jeblad@gmail.com >
 */
class RenderAdaptTest extends Scribunto_LuaEngineTestBase {

	protected static $moduleName = 'RenderAdaptTest';

	/**
	 * @slowThreshold 1000
	 * @see Scribunto_LuaEngineTestBase::getTestModules()
	 * @return configuration data
	 */
	protected function getTestModules() {
		return parent::getTestModules() + [
			'RenderAdaptTest' => __DIR__ . '/RenderAdaptTest.lua'
		];
	}
}
