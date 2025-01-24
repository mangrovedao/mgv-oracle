// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMgvMonitor, MgvLib, OLKey, Density, DensityLib} from "@mgv/src/core/MgvLib.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {IPriceSource} from "./interfaces/IPriceSource.sol";
import {IPriceSourceFactory} from "./interfaces/IPriceSourceFactory.sol";
import {SafeCast} from "@openzeppelin-contracts/utils/math/SafeCast.sol";
import {MgvPriceOracleErrors} from "./lib/MgvPriceOracleErrors.sol";

/**
 * @title MgvPriceOracle
 * @notice Oracle contract that provides price and density information for Mangrove
 * @dev Implements IMgvMonitor interface and inherits Ownable for access control
 */
contract MgvPriceOracle is IMgvMonitor, Ownable {
  using SafeCast for uint256;

  /**
   * @notice Struct to store price feed information
   * @param isFeed Whether the source is a price feed (true) or constant price (false)
   * @param source Address of price feed contract or encoded constant price
   */
  struct PriceFeed {
    bool isFeed;
    address source;
  }

  /// @notice Mapping of token addresses to their price feed information
  mapping(address token => PriceFeed feed) private _prices;

  /// @notice Address authorized to update gas prices
  address public gasBot;

  /**
   * @notice Struct to store multiplier and gas price together for gas optimization
   * @param multiplier64x64 Price multiplier in 64.64 fixed point format
   * @param gasprice Current gas price
   */
  struct MultiplierAndGasPrice {
    uint128 multiplier64x64;
    uint128 gasprice;
  }

  /// @notice Storage for multiplier and gas price values
  MultiplierAndGasPrice private multiplierAndGasPrice;

  /**
   * @notice Contract constructor
   * @param _gasBot Address authorized to update gas prices
   * @param _gasPrice Initial gas price
   * @param _multiplier64x64 Initial price multiplier in 64.64 fixed point format
   */
  constructor(address _gasBot, uint128 _gasPrice, uint128 _multiplier64x64) Ownable(msg.sender) {
    gasBot = _gasBot;
    multiplierAndGasPrice.gasprice = _gasPrice;
    multiplierAndGasPrice.multiplier64x64 = _multiplier64x64;
  }

  /**
   * @notice Sets a constant price for a token
   * @param token Address of the token
   * @param price Constant price value
   * @dev Price is stored as an address by converting to uint160
   */
  function setPriceFromConstant(address token, uint256 price) external onlyOwner {
    _prices[token] = PriceFeed({isFeed: false, source: address(price.toUint160())});
  }

  /**
   * @notice Sets a price feed for a token
   * @param token Address of the token
   * @param feed Address of the price feed contract
   */
  function setPriceFromFeed(address token, address feed) external onlyOwner {
    _prices[token] = PriceFeed({isFeed: true, source: feed});
  }

  /**
   * @notice Creates and sets a price feed from a factory
   * @param token Address of the token
   * @param factory Factory contract to create price source
   * @param args Arguments for price source creation
   */
  function setPriceFromFactory(address token, IPriceSourceFactory factory, bytes calldata args) external onlyOwner {
    _prices[token] = PriceFeed({isFeed: true, source: address(factory.createPriceSource(token, args))});
  }

  /**
   * @notice Sets the price multiplier
   * @param _multiplier64x64 New multiplier in 64.64 fixed point format
   */
  function setMultiplier(uint128 _multiplier64x64) external onlyOwner {
    multiplierAndGasPrice.multiplier64x64 = _multiplier64x64;
  }

  /**
   * @notice Sets the gas price
   * @param _gasPrice New gas price
   * @dev Only callable by gasBot address
   */
  function setGasPrice(uint128 _gasPrice) external {
    if (msg.sender != gasBot) revert MgvPriceOracleErrors.OnlyGasbot();
    multiplierAndGasPrice.gasprice = _gasPrice;
  }

  /**
   * @notice Gets the current price of a token
   * @param token Address of the token
   * @return Current price from feed or constant
   */
  function priceOf(address token) public view returns (uint256) {
    PriceFeed memory feed = _prices[token];
    if (feed.isFeed) {
      return IPriceSource(feed.source).getPrice(token);
    }
    return uint256(uint160(feed.source));
  }

  /**
   * @notice Converts a price to density using the multiplier
   * @param price Raw price value
   * @param _multiplier64x64 Multiplier in 64.64 fixed point format
   * @return density Calculated density
   */
  function _fromPriceToDensity(uint256 price, uint256 _multiplier64x64) internal pure returns (Density density) {
    uint256 density96x32 = (_multiplier64x64 * price) >> 32;
    density = DensityLib.from96X32(density96x32);
  }

  /**
   * @notice Gets the current density for a token
   * @param token Address of the token
   * @return density Current density value
   */
  function densityOf(address token) public view returns (Density density) {
    uint256 price = priceOf(token);
    density = _fromPriceToDensity(price, multiplierAndGasPrice.multiplier64x64);
  }

  /**
   * @notice Gets the current gas price
   * @return Current gas price value
   */
  function gasPrice() public view returns (uint256) {
    return multiplierAndGasPrice.gasprice;
  }

  /**
   * @notice Gets the current multiplier
   * @return Current multiplier in 64.64 fixed point format
   */
  function multiplier64x64() public view returns (uint256) {
    return multiplierAndGasPrice.multiplier64x64;
  }

  /**
   * @notice Gets all price-related information for a token
   * @param token Address of the token to get information for
   * @return price Current price of the token
   * @return density Current density calculated from price and multiplier
   * @return feed Address of the price feed source (if using a feed)
   * @return isFeed Whether the token uses a price feed (true) or constant price (false)
   */
  function infosForToken(address token) public view returns (uint256 price, Density density, address feed, bool isFeed) {
    MultiplierAndGasPrice memory _multiplierAndGasPrice = multiplierAndGasPrice;
    PriceFeed memory _priceFeed = _prices[token];

    if (_priceFeed.isFeed) {
      price = IPriceSource(_priceFeed.source).getPrice(token);
      feed = _priceFeed.source;
    } else {
      price = uint256(uint160(_priceFeed.source));
    }

    isFeed = _priceFeed.isFeed;
    density = _fromPriceToDensity(price, _multiplierAndGasPrice.multiplier64x64);
  }

  /**
   * @notice Callback for successful order execution
   * @param sor Order information
   * @param taker Address of the taker
   * @dev Currently does nothing
   */
  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker) external override {
    // Do nothing
  }

  /**
   * @notice Callback for failed order execution
   * @param sor Order information
   * @param taker Address of the taker
   * @dev Currently does nothing
   */
  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external override {
    // Do nothing
  }

  /**
   * @notice Reads current gas price and density for a token
   * @param olKey Struct containing token information
   * @return gasprice Current gas price
   * @return density Current density for the token
   */
  function read(OLKey memory olKey) external view override returns (uint256 gasprice, Density density) {
    MultiplierAndGasPrice memory _multiplierAndGasPrice = multiplierAndGasPrice;

    gasprice = _multiplierAndGasPrice.gasprice;
    density = _fromPriceToDensity(priceOf(olKey.outbound_tkn), _multiplierAndGasPrice.multiplier64x64);
  }
}
