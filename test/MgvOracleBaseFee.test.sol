// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2 as console, Vm} from "forge-std/Test.sol";
import { MgvOracleBaseFee } from "../src/MgvOracleBaseFee.sol";

contract MgvOracleBaseFeeTest is Test {
  MgvOracleBaseFee oracle;
  
  function setUp() public {
    oracle = new MgvOracleBaseFee(address(this), 10000);
  }

  function test_gasPrice() public {
    vm.fee(1e6);
    assertEq(oracle.gasPrice(), 1);
  }

  function test_lowGaspPrice() public {
    vm.fee(1e5);
    assertEq(oracle.gasPrice(), 1);
  }

  function test_zeroGasPrice() public {
    vm.fee(0);
    assertEq(oracle.gasPrice(), 0);
  }

  function test_slightlyHigherGasPrice() public {
    vm.fee(1e6 + 1e5);
    assertEq(oracle.gasPrice(), 2);
  }
}
