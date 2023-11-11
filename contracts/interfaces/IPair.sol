// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPair {
    function burn(address to) external returns (uint amount0, uint amount1);
    function claimFees() external returns (uint, uint);
    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function stable() external view returns (bool);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function tokens() external returns (address, address);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
}