// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./zapper-base.sol";
import "../interfaces/gaugeproxy.sol";

contract SnowglobeZapAvaxPangolin is ZapperBase {
    address public gaugeProxy = 0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27;

    constructor()
        public
        ZapperBase(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106)
    {}

    function zapOutAndSwap(
        address snowglobe,
        uint256 withdrawAmount,
        address desiredToken,
        uint256 desiredTokenOutMin
    ) public override {
        (IGlobe vault, IUniPair pair) = _getVaultPair(snowglobe);
        address token0 = pair.token0();
        address token1 = pair.token1();
        require(
            token0 == desiredToken || token1 == desiredToken,
            "desired token not present in liquidity pair"
        );

        vault.safeTransferFrom(msg.sender, address(this), withdrawAmount);
        vault.withdraw(withdrawAmount);
        _removeLiquidity(address(pair), address(this));

        address swapToken = token1 == desiredToken ? token0 : token1;
        address[] memory path = new address[](2);
        path[0] = swapToken;
        path[1] = desiredToken;

        _approveTokenIfNeeded(path[0], address(router));
        IPangolinRouter(router).swapExactTokensForTokens(
            IERC20(swapToken).balanceOf(address(this)),
            desiredTokenOutMin,
            path,
            address(this),
            block.timestamp
        );

        _returnAssets(path);
    }

    function _swapAndStake(
        address snowglobe,
        uint256 tokenAmountOutMin,
        address tokenIn
    ) public override {
        (IGlobe vault, IUniPair pair) = _getVaultPair(snowglobe);

        (uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
        require(
            reserveA > minimumAmount && reserveB > minimumAmount,
            "Liquidity pair reserves too low"
        );

        bool isInputA = pair.token0() == tokenIn;
        require(
            isInputA || pair.token1() == tokenIn,
            "Input token not present in liquidity pair"
        );

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = isInputA ? pair.token1() : pair.token0();

        uint256 fullInvestment = IERC20(tokenIn).balanceOf(address(this));
        uint256 swapAmountIn;
        if (isInputA) {
            swapAmountIn = _getSwapAmount(fullInvestment, reserveA, reserveB);
        } else {
            swapAmountIn = _getSwapAmount(fullInvestment, reserveB, reserveA);
        }

        _approveTokenIfNeeded(path[0], address(router));
        uint256[] memory swappedAmounts = IPangolinRouter(router)
            .swapExactTokensForTokens(
                swapAmountIn,
                tokenAmountOutMin,
                path,
                address(this),
                block.timestamp
            );

        _approveTokenIfNeeded(path[1], address(router));
        (, , uint256 amountLiquidity) = IPangolinRouter(router).addLiquidity(
            path[0],
            path[1],
            fullInvestment.sub(swappedAmounts[0]),
            swappedAmounts[1],
            1,
            1,
            address(this),
            block.timestamp
        );

        _approveTokenIfNeeded(address(pair), address(vault));
        vault.deposit(amountLiquidity);

        //taking receipt token and sending back to user
        vault.safeTransfer(msg.sender, vault.balanceOf(address(this)));

        //interact with gauge proxy to get gauge address
        address gaugeAddress = IGaugeProxyV2(gaugeProxy).getGauge(snowglobe);

        //deposit for into gauge
        IGaugeV2(gaugeAddress).depositFor(
            vault.balanceOf(msg.sender),
            msg.sender
        );

        _returnAssets(path);
    }

    function _getSwapAmount(
        uint256 investmentA,
        uint256 reserveA,
        uint256 reserveB
    ) public view override returns (uint256 swapAmount) {
        uint256 halfInvestment = investmentA.div(2);
        uint256 nominator = IPangolinRouter(router).getAmountOut(
            halfInvestment,
            reserveA,
            reserveB
        );
        uint256 denominator = IPangolinRouter(router).quote(
            halfInvestment,
            reserveA.add(halfInvestment),
            reserveB.sub(nominator)
        );
        swapAmount = investmentA.sub(
            Babylonian.sqrt(
                (halfInvestment * halfInvestment * nominator) / denominator
            )
        );
    }

    function estimateSwap(
        address snowglobe,
        address tokenIn,
        uint256 fullInvestmentIn
    )
        public
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            address swapTokenOut
        )
    {
        (, IUniPair pair) = _getVaultPair(snowglobe);

        bool isInputA = pair.token0() == tokenIn;
        require(
            isInputA || pair.token1() == tokenIn,
            "Input token not present in liquidity pair"
        );

        (uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
        (reserveA, reserveB) = isInputA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);

        swapAmountIn = _getSwapAmount(fullInvestmentIn, reserveA, reserveB);
        swapAmountOut = IPangolinRouter(router).getAmountOut(
            swapAmountIn,
            reserveA,
            reserveB
        );
        swapTokenOut = isInputA ? pair.token1() : pair.token0();
    }
}