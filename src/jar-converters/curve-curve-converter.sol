// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

import "../interfaces/uniswapv2.sol";
import "../interfaces/curve.sol";

// Converts Curve LP Tokens to UNI LP Tokens
contract CurveCurveJarConverter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Factory public factory = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );
    UniswapRouterV2 public router = UniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct Params {
        address fromUnderlying;
        address fromCurve;
        address fromCurveLP;
        bytes4 fromCurveFunctionSig;
        uint256 fromCurvePoolSize;
        uint256 fromCurveUnderlyingIndex;
        address toUnderlying;
        address toCurve;
        address toCurveLP;
        bytes4 toCurveFunctionSig;
        uint256 toCurvePoolSize;
        uint256 toCurveUnderlyingIndex;
    }

    // Curve LP -> Curve LP
    function convert(
        address _refundExcess, // address to send the excess amount
        uint256 _amount, // UNI LP Amount
        bytes calldata _data
    ) external returns (uint256) {
        Params memory params = abi.decode(_data, (Params));

        // Get LP Tokens
        IERC20(params.fromCurveLP).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // Remove liquidity from from Curve
        uint256[] memory removeLiquidity = new uint256[](
            params.fromCurvePoolSize
        );
        bytes memory fromCallData = abi.encodePacked(
            params.fromCurveFunctionSig,
            _amount,
            removeLiquidity
        );

        IERC20(params.fromCurveLP).safeApprove(params.fromCurve, 0);
        IERC20(params.fromCurveLP).safeApprove(params.fromCurve, _amount);

        (bool success, ) = params.fromCurve.call(fromCallData);
        require(success, "!success");

        // Swap on Uniswap if not the same
        if (params.fromUnderlying != params.toUnderlying) {
            swapUniswap(
                params.fromUnderlying,
                params.toUnderlying,
                IERC20(params.fromUnderlying).balanceOf(address(this))
            );
        }

        // Supply liquidity to to curve
        uint256[] memory supplyLiquidity = new uint256[](
            params.toCurvePoolSize
        );
        uint256 _supply = IERC20(params.toUnderlying).balanceOf(address(this));
        supplyLiquidity[params.toCurveUnderlyingIndex] = _supply;
        bytes memory callData = abi.encodePacked(
            params.toCurveFunctionSig,
            supplyLiquidity,
            uint256(0)
        );

        IERC20(params.toUnderlying).safeApprove(params.toCurve, 0);
        IERC20(params.toUnderlying).safeApprove(params.toCurve, _supply);
        (success, ) = params.toCurve.call(callData);
        require(success, "!success");

        uint256 _to = IERC20(params.toCurveLP).balanceOf(address(this));
        IERC20(params.toCurveLP).safeTransfer(msg.sender, _to);

        return _to;
    }

    function swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        // Swap with uniswap
        IERC20(_from).safeApprove(address(router), 0);
        IERC20(_from).safeApprove(address(router), _amount);

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        router.swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }
}
