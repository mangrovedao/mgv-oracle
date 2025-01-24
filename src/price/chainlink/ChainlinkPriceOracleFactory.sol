// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPriceSourceFactory} from "../interfaces/IPriceSourceFactory.sol";
import {ChainlinkPriceOracle} from "./ChainlinkPriceOracle.sol";
import {IPriceSource} from "../interfaces/IPriceSource.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title ChainlinkPriceOracleFactory
 * @notice Factory contract for creating ChainlinkPriceOracle instances
 * @dev Implements IPriceSourceFactory to create price oracles that use Chainlink price feeds
 */
contract ChainlinkPriceOracleFactory is IPriceSourceFactory {
  /**
   * @notice Creates a new ChainlinkPriceOracle instance for a given token
   * @dev The data parameter should be ABI encoded with four AggregatorV3Interface addresses for the price feeds
   * @param token The token address this price oracle will provide prices for
   * @param data ABI encoded parameters containing the four Chainlink price feed addresses:
   *             - baseFeed1: First base asset price feed
   *             - baseFeed2: Second base asset price feed
   *             - quoteFeed1: First quote asset price feed
   *             - quoteFeed2: Second quote asset price feed
   * @return priceSource The address of the newly created ChainlinkPriceOracle contract
   */
  function createPriceSource(address token, bytes calldata data) external returns (IPriceSource priceSource) {
    (
      AggregatorV3Interface baseFeed1,
      AggregatorV3Interface baseFeed2,
      AggregatorV3Interface quoteFeed1,
      AggregatorV3Interface quoteFeed2
    ) = abi.decode(data, (AggregatorV3Interface, AggregatorV3Interface, AggregatorV3Interface, AggregatorV3Interface));

    uint8 outputDecimals = IERC20Metadata(token).decimals();

    return new ChainlinkPriceOracle(baseFeed1, baseFeed2, quoteFeed1, quoteFeed2, outputDecimals);
  }
}
