// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ChainlinkConsumer} from "./lib/ChainlinkConsumer.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IPriceSource} from "../interfaces/IPriceSource.sol";
import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";

/**
 * @title ChainlinkPriceOracle
 * @notice Price oracle that combines up to 4 Chainlink price feeds to calculate a final price
 * @dev Implements IPriceSource interface and uses ChainlinkConsumer library for feed interactions
 */
contract ChainlinkPriceOracle is IPriceSource {
  using ChainlinkConsumer for AggregatorV3Interface;
  using Math for uint256;

  /// @notice First base price feed (numerator)
  AggregatorV3Interface public immutable BASE_FEED1;
  /// @notice Second base price feed (numerator), optional
  AggregatorV3Interface public immutable BASE_FEED2;
  /// @notice First quote price feed (denominator)
  AggregatorV3Interface public immutable QUOTE_FEED1;
  /// @notice Second quote price feed (denominator), optional
  AggregatorV3Interface public immutable QUOTE_FEED2;

  /// @notice Number of decimals in the output price
  uint8 public immutable OUTPUT_DECIMALS;

  /// @notice Multiplier applied to base feeds to normalize decimals
  uint256 public immutable BASE_FEED_MULTIPLIER;
  /// @notice Multiplier applied to quote feeds to normalize decimals
  uint256 public immutable QUOTE_FEED_MULTIPLIER;

  /**
   * @notice Constructs a new ChainlinkPriceOracle
   * @dev Calculates multipliers to normalize decimal places between feeds
   * @param baseFeed1 First base price feed (numerator)
   * @param baseFeed2 Second base price feed (numerator), can be zero address if not needed
   * @param quoteFeed1 First quote price feed (denominator)
   * @param quoteFeed2 Second quote price feed (denominator), can be zero address if not needed
   * @param outputDecimals Number of decimals desired in the output price
   */
  constructor(
    AggregatorV3Interface baseFeed1,
    AggregatorV3Interface baseFeed2,
    AggregatorV3Interface quoteFeed1,
    AggregatorV3Interface quoteFeed2,
    uint8 outputDecimals
  ) {
    BASE_FEED1 = baseFeed1;
    BASE_FEED2 = baseFeed2;
    QUOTE_FEED1 = quoteFeed1;
    QUOTE_FEED2 = quoteFeed2;
    OUTPUT_DECIMALS = outputDecimals;

    // Calculate the difference in decimals between base and quote feeds
    int256 resulting_decimals = int256(BASE_FEED1.getDecimals()) + int256(BASE_FEED2.getDecimals())
      - int256(QUOTE_FEED1.getDecimals()) - int256(QUOTE_FEED2.getDecimals());

    unchecked {
      int256 output_decimals = int256(uint256(outputDecimals));

      // Set multipliers to normalize decimals to match desired output decimals
      if (resulting_decimals < output_decimals) {
        BASE_FEED_MULTIPLIER = 10 ** uint256(output_decimals - resulting_decimals);
        QUOTE_FEED_MULTIPLIER = 1;
      } else {
        BASE_FEED_MULTIPLIER = 1;
        QUOTE_FEED_MULTIPLIER = 10 ** uint256(resulting_decimals - output_decimals);
      }
    }
  }

  /**
   * @notice Gets the current price by combining the Chainlink feed prices
   * @dev Multiplies base feeds and divides by quote feeds, applying decimal normalization
   * @param token Address of the token (unused but required by interface)
   * @return price The calculated price with OUTPUT_DECIMALS decimal places
   */
  function getPrice(address token) external view returns (uint256 price) {
    token; // unused
    price = BASE_FEED_MULTIPLIER.mulDiv(
      BASE_FEED1.getPrice() * BASE_FEED2.getPrice(),
      QUOTE_FEED_MULTIPLIER * QUOTE_FEED1.getPrice() * QUOTE_FEED2.getPrice(),
      Math.Rounding.Ceil
    );
  }
}
