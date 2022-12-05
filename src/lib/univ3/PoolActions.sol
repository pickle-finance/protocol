// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "../../interfaces/univ3/IUniswapV3Pool.sol";
import "./PoolVariables.sol";
import "./SafeCast.sol";

/// @title This library is created to conduct a variety of burn liquidity methods
library PoolActions {
    using PoolVariables for IUniswapV3Pool;
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /**
     * @notice Withdraws liquidity in share proportion to the Sorbetto's totalSupply.
     * @param pool Uniswap V3 pool
     * @param tickLower The lower tick of the range
     * @param tickUpper The upper tick of the range
     * @param totalSupply The amount of total shares in existence
     * @param share to burn
     * @param to Recipient of amounts
     * @return amount0 Amount of token0 withdrawed
     * @return amount1 Amount of token1 withdrawed
     */
    function burnLiquidityShare(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 totalSupply,
        uint256 share,
        address to
    ) internal returns (uint256 amount0, uint256 amount1) {
        require(totalSupply > 0, "TS");
        uint128 liquidityInPool = pool.positionLiquidity(tickLower, tickUpper);
        uint256 liquidity = uint256(liquidityInPool).mul(share) / totalSupply;

        if (liquidity > 0) {
            (amount0, amount1) = pool.burn(tickLower, tickUpper, liquidity.toUint128());

            if (amount0 > 0 || amount1 > 0) {
                // collect liquidity share
                (amount0, amount1) = pool.collect(to, tickLower, tickUpper, amount0.toUint128(), amount1.toUint128());
            }
        }
    }

    /**
     * @notice Withdraws exact amount of liquidity
     * @param pool Uniswap V3 pool
     * @param tickLower The lower tick of the range
     * @param tickUpper The upper tick of the range
     * @param liquidity to burn
     * @param to Recipient of amounts
     * @return amount0 Amount of token0 withdrawed
     * @return amount1 Amount of token1 withdrawed
     */
    function burnExactLiquidity(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint128 liquidityInPool = pool.positionLiquidity(tickLower, tickUpper);
        require(liquidityInPool >= liquidity, "TML");
        (amount0, amount1) = pool.burn(tickLower, tickUpper, liquidity);

        if (amount0 > 0 || amount1 > 0) {
            // collect liquidity share including earned fees
            (amount0, amount0) = pool.collect(to, tickLower, tickUpper, amount0.toUint128(), amount1.toUint128());
        }
    }

    /**
     * @notice Withdraws all liquidity in a range from Uniswap pool
     * @param pool Uniswap V3 pool
     * @param tickLower The lower tick of the range
     * @param tickUpper The upper tick of the range
     */
    function burnAllLiquidity(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        // Burn all liquidity in this range
        uint128 liquidity = pool.positionLiquidity(tickLower, tickUpper);
        if (liquidity > 0) {
            pool.burn(tickLower, tickUpper, liquidity);
        }

        // Collect all owed tokens
        pool.collect(address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max);
    }
}
