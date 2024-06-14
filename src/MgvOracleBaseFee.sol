// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IMgvMonitor, MgvLib, OLKey, Density } from "@mgv/src/core/MgvLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract MgvOracleBaseFee is IMgvMonitor, Ownable {

  uint baseFeeMultiplier;
  uint constant TEN_THOUSAND = 10_000;

  Density constant NO_DENSITY = Density.wrap(type(uint).max);

  error InvalidBaseFeeMultiplier();

  event BaseFeeMultiplierChanged(uint oldBaseFeeMultiplier, uint newBaseFeeMultiplier);

  constructor(address admin, uint _baseFeeMultiplier) Ownable(admin) {
    _internalSetBaseFeeMultiplier(_baseFeeMultiplier);
  }

  function _internalSetBaseFeeMultiplier(uint _baseFeeMultiplier) internal {
    if (_baseFeeMultiplier == 0) revert InvalidBaseFeeMultiplier();
    emit BaseFeeMultiplierChanged(baseFeeMultiplier, _baseFeeMultiplier);
    baseFeeMultiplier = _baseFeeMultiplier;
  }

  function setBaseFeeMultiplier(uint _baseFeeMultiplier) external onlyOwner {
    _internalSetBaseFeeMultiplier(_baseFeeMultiplier);
  }

  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker) external override {
    // Do nothing
  }

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external override {
    // Do nothing
  }

  function _toMwei(uint weis) internal pure returns (uint mwei) {
    mwei = weis / 1e6;
    if ((weis / 1e5) % 10 > 0) mwei += 1;
    if (mwei == 0 && weis > 0) mwei = 1;
  }

  function gasPrice() public view returns (uint gasprice) {
    gasprice = _toMwei(block.basefee * baseFeeMultiplier / TEN_THOUSAND);
  }

  function read(OLKey memory) external view override returns (uint gasprice, Density density) {
    gasprice = gasPrice();
    density = NO_DENSITY;
  }
}
