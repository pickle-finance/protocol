// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

import "../interfaces/uniswapv2.sol";
import "../interfaces/curve.sol";

// Converts UNI LP Tokens to Curve LP Tokens
contract UniCurveJarConverter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    UniswapRouterV2 public router = UniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct Params {
        address curve;
        bytes4 curveFunctionSig; // Function signature for adding liquidity to curve pool
        uint256 curvePoolSize; // Amount of tokens in curve pool
        uint256 curveUnderlyingIndex; // Underlying index in curve
        address from; // UNI LP - We always assume its a weth pair
        address fromUnderlying; // The otherside of UNI LP that isn't WETH
        address to; // Curve LP
        address toUnderlying; // Some Curve LP (wbtc, or some stablecoin)
    }

    // UNI LP -> Curve LP
    function convert(
        address _refundExcess, // address to send the excess amount when adding liquidity
        uint256 _amount, // UNI LP Amount
        bytes calldata _data
    ) external returns (uint256) {
        Params memory params = abi.decode(_data, (Params));

        // Get LP Tokens
        IERC20(params.from).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // Get Uniswap pair
        IUniswapV2Pair fromPair = IUniswapV2Pair(params.from);

        // Remove liquidity
        IERC20(params.from).safeApprove(address(router), 0);
        IERC20(params.from).safeApprove(address(router), _amount);
        router.removeLiquidity(
            fromPair.token0(),
            fromPair.token1(),
            _amount,
            0,
            0,
            address(this),
            now + 60
        );

        // Convert weth -> underlying
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = params.toUnderlying;

        IERC20(weth).safeApprove(address(router), 0);
        IERC20(weth).safeApprove(address(router), uint256(-1));
        router.swapExactTokensForTokens(
            IERC20(weth).balanceOf(address(this)),
            0,
            path,
            address(this),
            now + 60
        );

        // Convert the other asset into curve underlying if its not an underlying
        address other = fromPair.token0() != weth
            ? fromPair.token0()
            : fromPair.token1();

        if (other != params.toUnderlying) {
            path = new address[](3);
            path[0] = other;
            path[1] = weth;
            path[2] = params.toUnderlying;

            IERC20(other).safeApprove(address(router), 0);
            IERC20(other).safeApprove(address(router), uint256(-1));
            router.swapExactTokensForTokens(
                IERC20(other).balanceOf(address(this)),
                0,
                path,
                address(this),
                now + 60
            );
        }

        // Add liquidity to curve
        IERC20(params.toUnderlying).safeApprove(params.curve, 0);
        IERC20(params.toUnderlying).safeApprove(params.curve, uint256(-1));

        uint256 _toUnderlying = IERC20(params.toUnderlying).balanceOf(
            address(this)
        );
        uint256[] memory liquidity = new uint256[](params.curvePoolSize);
        liquidity[params.curveUnderlyingIndex] = _toUnderlying;

        bytes memory callData = abi.encodePacked(
            params.curveFunctionSig,
            liquidity,
            uint256(0)
        );

        (bool success, ) = params.curve.call(callData);
        require(success, "!success");

        // Sends token back to user
        uint256 _to = IERC20(params.to).balanceOf(address(this));
        IERC20(params.to).transfer(msg.sender, _to);

        return _to;
    }
}
