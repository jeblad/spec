<?php

namespace Pickle\Test\Full;

use Scribunto_LuaEngineTestBase;

/**
 * @group Pickle
 *
 * @license GPL-2.0-or-later
 *
 * @author John Erling Blad < jeblad@gmail.com >
 */
class RenderFrameFullTest extends Scribunto_LuaEngineTestBase {

	protected static $moduleName = 'RenderFrameFullTest';

	/**
	 * @slowThreshold 1000
	 * @see Scribunto_LuaEngineTestBase::getTestModules()
	 */
	protected function getTestModules() {
		return parent::getTestModules() + [
			'RenderFrameFullTest' => __DIR__ . '/RenderFrameFullTest.lua'
		];
	}
}
