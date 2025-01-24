// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IPriceSource } from "./IPriceSource.sol";

/**
 * @title IPriceSourceFactory
 * @notice Factory interface for creating price sources that implement IPriceSource
 */
interface IPriceSourceFactory {
  /**
   * @notice Creates a new price source for a given token
   * @dev The returned price source must implement IPriceSource interface and provide ETH-denominated prices
   * @param token The token address this price source will provide prices for
   * @param data Additional configuration data needed to create the price source
   * @return priceSource The address of the newly created price source contract
   */
  function createPriceSource(address token, bytes calldata data) external returns (IPriceSource priceSource);
}
