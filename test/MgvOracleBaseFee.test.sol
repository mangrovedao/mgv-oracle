// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2 as console, Vm} from "forge-std/Test.sol";
import {MgvOracleBaseFee, SafeCast, Math} from "../src/MgvOracleBaseFee.sol";

contract MgvOracleBaseFeeTest is Test {
  MgvOracleBaseFee oracle;

  /**
   * @notice Emitted when the base fee multiplier is changed
   * @param newBaseFeeMultiplier the new base fee multiplier
   */
  event SetBaseFeeMultiplier(uint256 newBaseFeeMultiplier);

  /**
   * @notice Emitted when the gas override is changed
   * @param newGasOverride the new gas override
   */
  event SetGasOverride(uint256 newGasOverride);

  uint256[] public fixtureGasOverride =
    [0, 300, uint256(type(uint32).max), uint256(type(uint32).max) + 1, type(uint256).max];

  uint256[] public fixtureBaseFeeMultiplier =
    [0, 300, 10_000, 20_000, uint256(type(uint32).max), uint256(type(uint32).max) + 1, type(uint256).max];

  uint128[] public fixtureBaseFee =
    [0, 1e5, 1e6, 1e5 + 1e6, uint128(type(uint32).max), uint128(type(uint32).max) + 1, type(uint128).max];

  function setUp() public {
    oracle = new MgvOracleBaseFee(address(this), 10_000);
  }

  function test_overrideGasPrice() public {
    vm.fee(1e5);
    assertEq(oracle.gasPrice(), 1);
    oracle.setGasOverride(5);
    assertEq(oracle.gasPrice(), 5);
  }

  function testFuzz_noOverride(uint128 baseFee, uint256 baseFeeMultiplier) public {
    vm.assume(baseFeeMultiplier > 0 && baseFeeMultiplier <= uint256(type(uint32).max));
    vm.fee(baseFee);
    vm.expectEmit(true, false, false, true, address(oracle));
    emit SetBaseFeeMultiplier(baseFeeMultiplier);
    oracle.setBaseFeeMultiplier(baseFeeMultiplier);
    assertEq(oracle.gasPrice(), Math.mulDiv(baseFee, baseFeeMultiplier, 1e6 * 1e4, Math.Rounding.Ceil));
  }

  // test set value

  function testFuzz_GasOverride(uint256 gasOverride) public {
    if (gasOverride > uint256(type(uint32).max)) {
      vm.expectRevert(abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 32, gasOverride));
      oracle.setGasOverride(gasOverride);
    } else {
      vm.expectEmit(true, false, false, true, address(oracle));
      emit SetGasOverride(gasOverride);
      oracle.setGasOverride(gasOverride);

      (, uint32 _gasOverride) = oracle.oracleStorage();
      assertEq(_gasOverride, gasOverride);
    }
  }

  function testFuzz_SetMultiplier(uint256 baseFeeMultiplier) public {
    if (baseFeeMultiplier == 0) {
      vm.expectRevert(abi.encodeWithSelector(MgvOracleBaseFee.InvalidBaseFeeMultiplier.selector));
      oracle.setBaseFeeMultiplier(baseFeeMultiplier);
    } else if (baseFeeMultiplier > uint256(type(uint32).max)) {
      vm.expectRevert(abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 32, baseFeeMultiplier));
      oracle.setBaseFeeMultiplier(baseFeeMultiplier);
    } else {
      vm.expectEmit(true, false, false, true, address(oracle));
      emit SetBaseFeeMultiplier(baseFeeMultiplier);
      oracle.setBaseFeeMultiplier(baseFeeMultiplier);

      (uint32 _baseFeeMultiplier,) = oracle.oracleStorage();
      assertEq(_baseFeeMultiplier, baseFeeMultiplier);
    }
  }
}
