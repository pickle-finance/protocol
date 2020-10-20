// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

import "../interfaces/uniswapv2.sol";
import "../interfaces/curve.sol";

// Converts Curve LP Tokens to UNI LP Tokens
contract CurveUniJarConverter {
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
        address curve;
        bytes4 curveFunctionSig; // Function signature for removing liquidity to curve pool
        uint256 curvePoolSize; // Amount of tokens in curve pool
        uint256 curveUnderlyingIndex; // Underlying index in curve
        address from; // Curve LP
        address fromUnderlying; // Curve's LP underlying (wbtc, or some stablecoin)
        address to; // Uniswap LP, always assumes its a weth pair
        address toUnderlying; // The other side of the weth pair
        // Note that if we need to convert all our underlying to ETH
        // It usually means the fromUnderlying is NOT part of the uni swap LP anymore.
        // e.g. curve 3crv -> remove_liquidity_dai -> weth/dai = false
        //      curve 3crv -> remove_liquidity_dai -> weth/btc = true
    }

    // Curve LP -> Uni LP
    function convert(
        address _refundExcess, // address to send the excess amount
        uint256 _amount, // UNI LP Amount
        bytes calldata _data
    ) external returns (uint256) {
        Params memory params = abi.decode(_data, (Params));

        // Only supports weth pairs
        IUniswapV2Pair toPair = IUniswapV2Pair(params.to);
        if (toPair.token0() != weth && toPair.token1() != weth) {
            revert("!weth-pair");
        }

        // Get LP Tokens
        IERC20(params.from).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // Remove liquidity from Curve
        uint256[] memory liquidity = new uint256[](params.curvePoolSize);

        bytes memory callData = abi.encodePacked(
            params.curveFunctionSig,
            _amount,
            liquidity
        );

        IERC20(params.fromUnderlying).safeApprove(params.curve, 0);
        IERC20(params.fromUnderlying).safeApprove(params.curve, _amount);

        (bool success, ) = params.curve.call(callData);
        require(success, "!success");

        // If fromUnderlying is not toUnderlying
        // We need to convert all our WETH into ETH
        // that means that the token withdrawn from
        // curve is not part of the lp token
        if (params.fromUnderlying != params.toUnderlying) {
            // Convert fromUnderlying to weth
            swapUniswap(params.fromUnderlying, weth);

            // Convert optimal amount of WETH to params.toUnderlying
            optimalUniswapOneSideSupply(toPair, weth, params.toUnderlying);
        }

        // Otherwise we convert an optimal amount from the fromUnderlying to weth
        else {
            optimalUniswapOneSideSupply(toPair, params.toUnderlying, weth);
        }

        // Supply liquidity and send LP tokens received to msg.sender
        uint256 _to = supplyUniswapLiquidity(msg.sender, weth, params.toUnderlying);    

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

    function getSwapAmt(uint256 amtA, uint256 resA) internal pure returns (uint256) {
        return sqrt(amtA.mul(resA.mul(3988000).add(amtA.mul(3988009)))).sub(amtA.mul(1997)).div(1994);
    }

    function swapUniswap(address from, address to) internal {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;

        if (from != weth && to != weth) {
            revert("!weth-pair");
        }

        uint256 _from = IERC20(from).balanceOf(address(this));

        IERC20(from).safeApprove(address(router), 0);
        IERC20(from).safeApprove(
            address(router),
            _from
        );
        router.swapExactTokensForTokens(
            _from,
            0,
            path,
            address(this),
            now + 60
        );
    }

    // https://blog.alphafinance.io/onesideduniswap/
    // https://github.com/AlphaFinanceLab/alphahomora/blob/88a8dfe4d4fa62b13b40f7983ee2c646f83e63b5/contracts/StrategyAddETHOnly.sol#L39
    // AlphaFinance is gripbook licensed
    function optimalUniswapOneSideSupply(IUniswapV2Pair pair, address from, address to) internal {
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

        router.swapExactTokensForTokens(
            aIn,
            0,
            path,
            address(this),
            now + 60
        );
    }

    function supplyUniswapLiquidity(address recipient, address token0, address token1) internal returns (uint256) {
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

        (,, uint256 _to) = router.addLiquidity(
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

    function refundExcessToken(IUniswapV2Pair pair, address recipient) internal {
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(token0).safeTransfer(recipient, IERC20(token0).balanceOf(address(this)));
        IERC20(token1).safeTransfer(recipient, IERC20(token1).balanceOf(address(this)));
    }
}
