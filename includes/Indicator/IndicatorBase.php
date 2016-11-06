<?php

namespace Spec;

/**
 * Indicator base
 * Encapsulates the abstract base class indicator as an adapter.
 *
 * @ingroup Extensions
 */
abstract class IndicatorBase implements IIndicator {

	use TNamedStrategy;

	/**
	 * Make a page status indicator link given status and url
	 *
	 * @param string $url to the internal or external page
	 * @return Html|null
	 */
	public function makeLink( $url, $lang = null ) {

		// Get the message containing the text to use for the link
		// @message spec-test-text-good
		// @message spec-test-text-pending
		// @message spec-test-text-failing
		// @message spec-test-text-missing
		// @message spec-test-text-unknown
		$msg = wfMessage( $this->getMessageKey() );
		$msg = $lang === null ? $msg->inContentLanguage() : $msg->inLanguage( $lang );
		if ( $msg->isDisabled() ) {
			return null;
		}

		// Build a link for the page status indicator
		$elem = \Html::rawElement(
			'a',
			[
				'href' => $url,
				'target' => '_blank',
				'class' => [ $this->getClassKey(), $this->getKey() ]
			],
			$msg->parse()
		);

		return $elem;
	}

	/**
	 * Make a page status indicator note given status
	 *
	 * @param string $status representing the state
	 * @return Html|null
	 */
	public function makeNote( $lang = null ) {

		// Get the message containing the text to use for the link
		// @message spec-test-text-good
		// @message spec-test-text-pending
		// @message spec-test-text-failing
		// @message spec-test-text-missing
		// @message spec-test-text-unknown
		$msg = wfMessage( $this->getMessageKey() );
		$msg = $lang === null ? $msg->inContentLanguage() : $msg->inLanguage( $lang );
		if ( $msg->isDisabled() ) {
			return null;
		}

		// Build a link for the page status indicator
		$elem = \Html::rawElement(
			'span',
			[
				'class' => [ $this->getClassKey(), $this->getKey() ]
			],
			$msg->parse()
		);

		return $elem;
	}

	/**
	 * Get the key
	 *
	 * @return string
	 */
	public function getKey() {
		return $this->getClassKey() . '-' . $this->opts['name'];
	}

	/**
	 * Get the messagekey
	 *
	 * @return string
	 */
	public function getMessageKey() {
		return 'spec-test-text-' . $this->opts['name'];
	}

	/**
	 * Get the class key
	 *
	 * @return string
	 */
	public function getClassKey() {
		return 'mw-speclink';
	}

	/**
	 * @see \Spec\IIndicator::addIndicator()
	 */
	public function addIndicator( \Title $title = null, \ParserOutput &$parserOutput ) {
		$elem = null;

		if ( $title === null ) {
			$elem = $this->makeNote();
		} else {
			$elem = $this->makeLink( $title->getLocalURL() );
		}

		if ( $elem !== null ) {
			$res = $parserOutput->setIndicator( $this->getClassKey(), $elem );
			$parserOutput->addModuleStyles( 'ext.spec.default' );
		}

		return $elem;
	}
}