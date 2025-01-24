// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MgvPriceOracle, Density, OLKey} from "../src/price/MgvPriceOracle.sol";
import {Test, console2 as console} from "forge-std/src/Test.sol";
import {AggregatorV3Interface} from "../src/price/chainlink/interfaces/AggregatorV3Interface.sol";
import {ChainlinkPriceOracleFactory} from "../src/price/chainlink/ChainlinkPriceOracleFactory.sol";
import {ERC20} from "@openzeppelin-contracts/token/ERC20/ERC20.sol";

contract MgvPriceOracleTest is Test {
  MgvPriceOracle public oracle;
  ChainlinkPriceOracleFactory public factory;
  uint256 baseFork;

  AggregatorV3Interface public ETH_USD = AggregatorV3Interface(0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70);
  AggregatorV3Interface public BTC_USD = AggregatorV3Interface(0x64c911996D3c6aC71f9b455B1E8E7266BcbD848F);
  AggregatorV3Interface public CBBTC_USD = AggregatorV3Interface(0x07DA0E54543a844a80ABE69c8A12F22B3aA59f9D);
  AggregatorV3Interface public CBETH_ETH = AggregatorV3Interface(0x806b4Ac04501c29769051e42783cF04dCE41440b);
  AggregatorV3Interface public CBETH_USD = AggregatorV3Interface(0xd7818272B9e248357d13057AAb0B417aF31E817d);

  ERC20 public ETH = ERC20(0x4200000000000000000000000000000000000006);
  ERC20 public CBBTC = ERC20(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf);
  ERC20 public CBETH = ERC20(0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22);
  ERC20 public USDC = ERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

  function setUp() public {
    baseFork = vm.createFork(vm.envString("BASE_RPC_URL"));
    vm.selectFork(baseFork);
    vm.rollFork(25_466_865);

    vm.label(address(ETH), "ETH");
    vm.label(address(CBBTC), "CBBTC");
    vm.label(address(CBETH), "CBETH");
    vm.label(address(USDC), "USDC");

    vm.label(address(ETH_USD), "Chainlink ETH/USD");
    vm.label(address(BTC_USD), "Chainlink BTC/USD");
    vm.label(address(CBBTC_USD), "Chainlink CBBTC/USD");
    vm.label(address(CBETH_ETH), "Chainlink CBETH/ETH");
    vm.label(address(CBETH_USD), "Chainlink CBETH/USD");

    uint128 multiplier = uint128(3 << 64) / (100 * 500_000);
    console.log("multiplier", multiplier);

    oracle = new MgvPriceOracle(address(this), 10, multiplier);
    factory = new ChainlinkPriceOracleFactory();
  }

  function test_densityFromChainlink() public {
    oracle.setPriceFromFactory(
      address(CBBTC), factory, abi.encode(address(ETH_USD), address(0), address(CBBTC_USD), address(0))
    );
    Density density = oracle.densityOf(address(CBBTC));
    uint256 minVolume = density.multiply(500_000);
    console.log("minVolume", minVolume);
  }

  function test_ConstantPrice() public {
    oracle.setPriceFromConstant(address(ETH), 1 ether);
    Density density = oracle.densityOf(address(ETH));
    uint256 minVolume = density.multiply(500_000);
    console.log("minVolume", minVolume);
  }

  function test_readFromChainLink() public {
    oracle.setPriceFromFactory(
      address(CBBTC), factory, abi.encode(address(ETH_USD), address(0), address(CBBTC_USD), address(0))
    );
    (uint256 price, Density density) = oracle.read(OLKey(address(CBBTC), address(0), 0));
    console.log("price", price);
    console.log("minVolume", density.multiply(500_000));
  }

  function test_readFromConstant() public {
    oracle.setPriceFromConstant(address(CBBTC), 1e18);
    (uint256 price, Density density) = oracle.read(OLKey(address(CBBTC), address(0), 0));
    console.log("price", price);
    console.log("minVolume", density.multiply(500_000));
  }
}
