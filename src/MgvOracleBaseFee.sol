// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMgvMonitor, MgvLib, OLKey, Density } from "@mgv/src/core/MgvLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";


contract MgvOracleBaseFee is IMgvMonitor, Ownable {

  /**
   * @notice Oracle storage
   * @param baseFeeMultiplier The base fee multiplier (in 1e4)
   * @param gasOverride The gas override (in mwei)
   */
  struct OracleStorage {
    uint32 baseFeeMultiplier;
    uint32 gasOverride;
  }

  /**
   * @notice Oracle storage
   */
  OracleStorage public oracleStorage;

  /**
   * @notice denominator for base fee multiplier
   */
  uint constant MWEI_TIMES_TEN_THOUSAND = 10_000 * 1e6;

  /**
   * @notice No density
   */
  Density constant NO_DENSITY = Density.wrap(type(uint).max);

  /**
   * @notice throws if base fee multiplier is 0
   */
  error InvalidBaseFeeMultiplier();

  /**
   * @notice Emitted when the base fee multiplier is changed
   * @param newBaseFeeMultiplier the new base fee multiplier
   */
  event SetBaseFeeMultiplier(uint newBaseFeeMultiplier);

  /**
   * @notice Emitted when the gas override is changed
   * @param newGasOverride the new gas override
   */
  event SetGasOverride(uint newGasOverride);

  /**
   * @notice Construct the oracle
   * @param admin the admin address
   * @param _baseFeeMultiplier the base fee multiplier
   */
  constructor(address admin, uint _baseFeeMultiplier) Ownable(admin) {
    _internalSetBaseFeeMultiplier(_baseFeeMultiplier);
    _internalSetGasOverride(0);
  }

  /**
   * @notice Set the base fee multiplier
   * @param _baseFeeMultiplier the base fee multiplier
   */
  function _internalSetBaseFeeMultiplier(uint _baseFeeMultiplier) internal {
    if (_baseFeeMultiplier == 0) revert InvalidBaseFeeMultiplier();
    uint32 baseFeeMultiplier = SafeCast.toUint32(_baseFeeMultiplier);
    emit SetBaseFeeMultiplier(baseFeeMultiplier);
    oracleStorage.baseFeeMultiplier = baseFeeMultiplier;
  }

  /**
   * @notice Set the gas override
   * @param _gasOverride the gas override
   */
  function _internalSetGasOverride(uint _gasOverride) internal {
    uint32 gasOverride = SafeCast.toUint32(_gasOverride);
    emit SetGasOverride(gasOverride);
    oracleStorage.gasOverride = gasOverride;
  }

  /**
   * @notice Set the base fee multiplier
   * @param baseFeeMultiplier the base fee multiplier
   */
  function setBaseFeeMultiplier(uint baseFeeMultiplier) external onlyOwner {
    _internalSetBaseFeeMultiplier(baseFeeMultiplier);
  }

  /**
   * @notice Set the gas override
   * @param gasOverride the gas override
   */
  function setGasOverride(uint gasOverride) external onlyOwner {
    _internalSetGasOverride(gasOverride);
  }

  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker) external override {
    // Do nothing
  }

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external override {
    // Do nothing
  }

  /**
   * @notice Gets the gas price
   */
  function gasPrice() public view returns (uint gasprice) {
    OracleStorage memory _oracleStorage = oracleStorage;
    if (_oracleStorage.gasOverride > 0) return _oracleStorage.gasOverride;
    gasprice = Math.mulDiv(block.basefee, _oracleStorage.baseFeeMultiplier, MWEI_TIMES_TEN_THOUSAND, Math.Rounding.Ceil);
  }

  /**
   * @notice Read the oracle
   */
  function read(OLKey memory) external view override returns (uint gasprice, Density density) {
    gasprice = gasPrice();
    density = NO_DENSITY;
  }
}
