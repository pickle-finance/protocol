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

    // Uni LP -> Uni LP
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

        // Swap fromUnderlying -> weth
        swapUniswap(params.fromUnderlying, weth);

        // Optimal swap from weth -> to.Underlying
        optimalUniswapOneSideSupply(toPair, weth, params.toUnderlying);

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

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getSwapAmt(uint256 amtA, uint256 resA)
        internal
        pure
        returns (uint256)
    {
        return
            sqrt(amtA.mul(resA.mul(3988000).add(amtA.mul(3988009))))
                .sub(amtA.mul(1997))
                .div(1994);
    }

    // https://blog.alphafinance.io/onesideduniswap/
    // https://github.com/AlphaFinanceLab/alphahomora/blob/88a8dfe4d4fa62b13b40f7983ee2c646f83e63b5/contracts/StrategyAddETHOnly.sol#L39
    // AlphaFinance is gripbook licensed
    function optimalUniswapOneSideSupply(
        IUniswapV2Pair pair,
        address from,
        address to
    ) internal {
        address[] memory path = new address[](2);

        // 1. Compute optimal amount of WETH to be converted
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        uint256 rIn = pair.token0() == from ? r0 : r1;
        uint256 aIn = getSwapAmt(rIn, IERC20(from).balanceOf(address(this)));

        // 2. Convert that from -> to
        path[0] = from;
        path[1] = to;

        IERC20(from).safeApprove(address(router), 0);
        IERC20(from).safeApprove(address(router), aIn);

        router.swapExactTokensForTokens(aIn, 0, path, address(this), now + 60);
    }

    function swapUniswap(address from, address to) internal {
        require(to != address(0));

        address[] memory path;

        if (from == weth || to == weth) {
            path = new address[](2);
            path[0] = from;
            path[1] = to;
        } else {
            path = new address[](3);
            path[0] = from;
            path[1] = weth;
            path[2] = to;
        }

        uint256 amount = IERC20(from).balanceOf(address(this));

        IERC20(from).safeApprove(address(router), 0);
        IERC20(from).safeApprove(address(router), amount);
        router.swapExactTokensForTokens(
            amount,
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
