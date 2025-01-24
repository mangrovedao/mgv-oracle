// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {SafeCast} from "@openzeppelin-contracts/utils/math/SafeCast.sol";

/**
 * @title ChainlinkConsumer
 * @notice Library for safely interacting with Chainlink price feeds
 * @dev Provides helper functions to read prices and decimals from Chainlink feeds
 */
library ChainlinkConsumer {
  /**
   * @notice Gets the latest price from a Chainlink feed
   * @dev Returns 1 if feed address is zero, otherwise gets latest answer and converts to uint256
   * @param feed The Chainlink price feed to query
   * @return The latest price from the feed as a uint256
   */
  function getPrice(AggregatorV3Interface feed) internal view returns (uint256) {
    if (address(feed) == address(0)) return 1;
    (, int256 answer,,,) = feed.latestRoundData();
    return SafeCast.toUint256(answer);
  }

  /**
   * @notice Gets the number of decimals used by a Chainlink feed
   * @dev Returns 0 if feed address is zero, otherwise gets decimals from the feed
   * @param feed The Chainlink price feed to query
   * @return The number of decimal places used by the feed
   */
  function getDecimals(AggregatorV3Interface feed) internal view returns (uint256) {
    if (address(feed) == address(0)) return 0;

    return feed.decimals();
  }
}
