// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "@mgv/forge-std/Script.sol";
import { MgvOracleBaseFee } from "../src/MgvOracleBaseFee.sol";
import { console2 as console } from "@mgv/forge-std/console2.sol";

contract MgvOracleBaseFeeDeployer is Script {
  function run() public {
    uint initialMultiplier = vm.envOr("MULTIPLIER", uint(10_000));
    vm.startBroadcast();
    address admin = vm.envOr("ADMIN", msg.sender);
    MgvOracleBaseFee oracle = new MgvOracleBaseFee(admin, initialMultiplier);
    vm.stopBroadcast();
    console.log("Deployed MgvOracleBaseFee at address:", address(oracle));
  }
}