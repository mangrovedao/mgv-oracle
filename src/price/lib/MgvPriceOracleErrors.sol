// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MgvPriceOracleErrors
 * @notice Library containing custom errors for the MgvPriceOracle contract
 * @dev Centralizes error definitions for better organization and gas efficiency
 */
library MgvPriceOracleErrors {
  /**
   * @notice Thrown when a function restricted to the gasBot is called by another address
   * @dev Used in functions that should only be callable by the authorized gas price updater
   */
  error OnlyGasbot();
}
