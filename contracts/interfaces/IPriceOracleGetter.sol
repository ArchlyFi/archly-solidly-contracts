// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Archly price oracle.
 **/

interface IPriceOracleGetter {
  /**
   * @dev returns the asset price
   * @param asset the address of the asset
   * @return the price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}
