// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IBaseV1GaugeFactory {
    function createGauge(address, address, address) external returns (address);
}