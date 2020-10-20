// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

import "../interfaces/uniswapv2.sol";
import "../interfaces/curve.sol";

// Converts Curve LP Tokens to UNI LP Tokens
contract UniUniJarConverter {
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
        address from; // Uniswap LP
        address fromUnderlying; // The other side of the weth pair
        address to; // Uniswap LP, always assumes its a weth pair
        address toUnderlying; // The other side of the weth pair
    }

    // Curve LP -> Uni LP
    function convert(
        address _refundExcess, // address to send the excess amount
        uint256 _amount, // UNI LP Amount
        bytes calldata _data
    ) external returns (uint256) {
        Params memory params = abi.decode(_data, (Params));

        // Only supports weth pairs
        IUniswapV2Pair fromPair = IUniswapV2Pair(params.from);
        if (fromPair.token0() != weth && fromPair.token1() != weth) {
            revert("!from-weth-pair");
        }

        IUniswapV2Pair toPair = IUniswapV2Pair(params.to);
        if (toPair.token0() != weth && toPair.token1() != weth) {
            revert("!to-weth-pair");
        }

        // Get LP Tokens
        IERC20(params.from).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // Remove liquidity from Uniswap
        removeUniswapLiquidity(fromPair);

        // Swap fromUnderlying -> weth -> toUnderlying
        swapUniswap(params.fromUnderlying, params.toUnderlying);

        // Supply liquidity and send LP tokens received to msg.sender
        uint256 _to = supplyUniswapLiquidity(
            msg.sender,
            weth,
            params.toUnderlying
        );

        // Refund any excess token
        refundExcessToken(toPair, _refundExcess);

        return _to;
    }

    function swapUniswap(address from, address to) internal {
        address[] memory path = new address[](3);
        path[0] = from;
        path[1] = weth;
        path[2] = to;

        if (from == weth && to == weth) {
            revert("weth-pair");
        }

        uint256 _from = IERC20(from).balanceOf(address(this));

        IERC20(from).safeApprove(address(router), 0);
        IERC20(from).safeApprove(address(router), _from);
        router.swapExactTokensForTokens(
            _from,
            0,
            path,
            address(this),
            now + 60
        );
    }

    function removeUniswapLiquidity(IUniswapV2Pair pair) internal {
        uint256 _balance = pair.balanceOf(address(this));
        pair.approve(address(router), _balance);

        router.removeLiquidity(
            pair.token0(),
            pair.token1(),
            _balance,
            0,
            0,
            address(this),
            now + 60
        );
    }

    function supplyUniswapLiquidity(
        address recipient,
        address token0,
        address token1
    ) internal returns (uint256) {
        // Add liquidity to uniswap
        IERC20(token0).safeApprove(address(router), 0);
        IERC20(token0).safeApprove(
            address(router),
            IERC20(token0).balanceOf(address(this))
        );

        IERC20(token1).safeApprove(address(router), 0);
        IERC20(token1).safeApprove(
            address(router),
            IERC20(token1).balanceOf(address(this))
        );

        (, , uint256 _to) = router.addLiquidity(
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            0,
            0,
            recipient,
            now + 60
        );

        return _to;
    }

    function refundExcessToken(IUniswapV2Pair pair, address recipient)
        internal
    {
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(token0).safeTransfer(
            recipient,
            IERC20(token0).balanceOf(address(this))
        );
        IERC20(token1).safeTransfer(
            recipient,
            IERC20(token1).balanceOf(address(this))
        );
    }
}
