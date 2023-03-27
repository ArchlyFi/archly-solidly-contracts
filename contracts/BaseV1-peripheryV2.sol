// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './interfaces/IBaseV1Factory.sol';
import './interfaces/IBaseV1Pair.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWTLOS.sol';
import './libraries/Math.sol';
import './BaseV1-periphery.sol';

contract BaseV1Router02 is BaseV1Router01 {
    using Math for uint;
    constructor(address _factory, address _wtlos) BaseV1Router01(_factory, _wtlos)
    {
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens)****
    function removeLiquidityTLOSSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountTLOSMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountTLOS) {
        (amountToken, amountTLOS) = removeLiquidity(
            token,
            address(wtlos),
            stable,
            liquidity,
            amountTokenMin,
            amountTLOSMin,
            address(this),
            deadline
        );
        _safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        wtlos.withdraw(amountTLOS);
        _safeTransferTLOS(to, amountTLOS);
    }
    
    function removeLiquidityTLOSWithPermitSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountTLOSMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountTLOS) {
        address pair = pairFor(token, address(wtlos), stable);
        uint value = approveMax ? type(uint).max : liquidity;
        IBaseV1Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountTLOS) = removeLiquidityTLOSSupportingFeeOnTransferTokens(
            token, stable, liquidity, amountTokenMin, amountTLOSMin, to, deadline
        );
    }
    
    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(route[] memory routes, address _to) internal virtual {
        for (uint i; i < routes.length; i++) {
            (address input, address output, bool stable) = (routes[i].from, routes[i].to, routes[i].stable);
            (address token0,) = sortTokens(input, output);
            IBaseV1Pair pair = IBaseV1Pair(pairFor(routes[i].from, routes[i].to, routes[i].stable));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                //(amountOutput,) = getAmountOut(amountInput, input, output, stable);
                amountOutput = pair.getAmountOut(amountInput, input);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < routes.length - 1 ? pairFor(routes[i+1].from, routes[i+1].to, routes[i+1].stable) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external ensure(deadline) {
        _safeTransferFrom(
            routes[0].from,
            msg.sender,
            pairFor(routes[0].from, routes[0].to, routes[0].stable),
            amountIn
        );
        uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(routes, to);
        require(
            IERC20(routes[routes.length - 1].to).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    
    function swapExactTLOSForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    )
    external
    payable
    ensure(deadline)
    {
        require(routes[0].from == address(wtlos), 'BaseV1Router: INVALID_PATH');
        uint amountIn = msg.value;
        wtlos.deposit{value: amountIn}();
        assert(wtlos.transfer(pairFor(routes[0].from, routes[0].to, routes[0].stable), amountIn));
        uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(routes, to);
        require(
            IERC20(routes[routes.length - 1].to).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    
    function swapExactTokensForTLOSSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    )
    external
    ensure(deadline)
    {
        require(routes[routes.length - 1].to == address(wtlos), 'BaseV1Router: INVALID_PATH');
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amountIn
        );
        _swapSupportingFeeOnTransferTokens(routes, address(this));
        uint amountOut = IERC20(address(wtlos)).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        wtlos.withdraw(amountOut);
        _safeTransferTLOS(to, amountOut);
    }
}