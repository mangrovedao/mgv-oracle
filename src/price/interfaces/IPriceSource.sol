// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceSource {
  /**
   * @notice Returns the amount of `token` (quote asset) that corresponds to 1 ETH (base asset)
   * @dev For example:
   * - If 1 ETH = 3500 USDC, then getPrice(USDC) returns 3500e6 (USDC has 6 decimals)
   * - If token = ETH, returns 1e18 
   * - Return value should account for token's decimals
   * - For tokens with price feeds, use ETH as base asset (e.g. ETH/USDC feed) and scale to token decimals
   * @param token The quote token address to get the price for
   * @return The amount of quote token that can be bought with 1 ETH, adjusted for decimals
   */
  function getPrice(address token) external view returns (uint256);
}
