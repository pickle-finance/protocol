// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-base.sol";
import "../../interfaces/backscratcher/IStrategyProxy.sol";
import "hardhat/console.sol";

contract StrategyFraxDaiUniV3 is StrategyUniV3Base {
    address public strategyProxy;

    address public frax_dai_pool = 0x97e7d56A0408570bA1a7852De36350f7713906ec;
    address public frax_dai_gauge = 0xF22471AC2156B489CC4a59092c56713F813ff53e;

    address public constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    address[] public rewardTokens = [FXS, DAI, FRAX];

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyUniV3Base(frax_dai_pool, -50, 50, _governance, _strategist, _controller, _timelock) {}

    // **** Views ****

    //for test only
    function setStrategyProxy(address _proxy) external {
        require(msg.sender == governance, "!governance");
        strategyProxy = _proxy;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyFraxDaiUniV3";
    }

    function harvest() public override onlyBenevolent {
        IStrategyProxy(strategyProxy).harvest(frax_dai_gauge, rewardTokens);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            console.log("rewardToken=> ", rewardTokens[i]);
            console.log("balance=> ", IERC20(rewardTokens[i]).balanceOf(address(this)));
        }

        uint256 _fxs = IERC20(FXS).balanceOf(address(this));

        IERC20(FXS).safeApprove(univ2Router2, 0);
        IERC20(FXS).safeApprove(univ2Router2, _fxs);

        _swapUniswap(FXS, FRAX, _fxs);
        console.log("\nAfter swap");
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            console.log("rewardToken=> ", rewardTokens[i]);
            console.log("balance=> ", IERC20(rewardTokens[i]).balanceOf(address(this)));
        }

        uint256 _frax = IERC20(FRAX).balanceOf(address(this));
        uint256 _dai = IERC20(DAI).balanceOf(address(this));
        uint256 _ratio = getProportion();
        console.log("_ratio=> ", _ratio);
        uint256 _amount1Desired = (_dai.add(_frax)).mul(_ratio).div(_ratio.add(1e18));

        uint256 _amount;
        address from;
        address to;

        if (_amount1Desired < _frax) {
            _amount = _frax.sub(_amount1Desired);
            from = FRAX;
            to = DAI;
        } else {
            _amount = _amount1Desired.sub(_frax);
            from = DAI;
            to = FRAX;
        }

        IERC20(from).safeApprove(univ3Router, 0);
        IERC20(from).safeApprove(univ3Router, _amount);

        ISwapRouter(univ3Router).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: from,
                tokenOut: to,
                fee: pool.fee(),
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: _amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        console.log("_ratio=> ", getProportion());
        console.log("\nafter second swap");

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            console.log("rewardToken=> ", rewardTokens[i]);
            console.log("balance=> ", IERC20(rewardTokens[i]).balanceOf(address(this)));
        }

        _distributePerformanceFeesAndDeposit();

        console.log("\nafter deposit");
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            console.log("rewardToken=> ", rewardTokens[i]);
            console.log("balance=> ", IERC20(rewardTokens[i]).balanceOf(address(this)));
        }
    }

    function liquidityOfPool() public view override returns (uint256) {
        return IStrategyProxy(strategyProxy).balanceOf(frax_dai_gauge);
    }

    function getHarvestable() public view returns (uint256, uint256) {}

    // **** Setters ****

    function deposit() public override {
        (uint256 _tokenId, ) = _wrapAllToNFT();
        nftManager.safeTransferFrom(address(this), strategyProxy, _tokenId);
        IStrategyProxy(strategyProxy).depositV3(
            frax_dai_gauge,
            _tokenId,
            IFraxGaugeBase(frax_dai_gauge).lock_time_min()
        );
    }

    function _withdrawSomeFromPool(uint256 _tokenId, uint128 _liquidity) internal {
        if (_tokenId == 0 || _liquidity == 0) return;
        (uint256 _a0Expect, uint256 _a1Expect) = pool.amountsForLiquidity(_liquidity, tick_lower, tick_upper);
        console.log("a0Expect => ", _a0Expect);
        console.log("a1Expect => ", _a1Expect);

        nftManager.decreaseLiquidity(
            IUniswapV3PositionsNFT.DecreaseLiquidityParams(
                _tokenId,
                _liquidity,
                _a0Expect,
                _a1Expect,
                block.timestamp + 300
            )
        );
        nftManager.collect(
            IUniswapV3PositionsNFT.CollectParams(_tokenId, address(this), type(uint128).max, type(uint128).max)
        );
    }

    function _withdrawSome(uint256 _liquidity) internal override returns (uint256, uint256) {
        LockedNFT[] memory lockedNfts = IStrategyProxy(strategyProxy).lockedNFTsOf(frax_dai_gauge);
        uint256[2] memory _balances = [token0.balanceOf(address(this)), token1.balanceOf(address(this))];

        uint256 _sum;
        uint256 _count;

        for (uint256 i = 0; i < lockedNfts.length; i++) {
            if (lockedNfts[i].token_id == 0 || lockedNfts[i].liquidity == 0) {
                _count++;
                continue;
            }
            _sum = _sum.add(IStrategyProxy(strategyProxy).withdrawV3(frax_dai_gauge, lockedNfts[i].token_id));
            _count++;
            if (_sum >= _liquidity) break;
        }
        console.log("   [withdrawSome] _sum => ", _sum);
        console.log("   [withdrawSome] _liquidity => ", _liquidity);

        require(_sum >= _liquidity, "insufficient liquidity");
        console.log("   [withdrawSome] _count => ", _count);

        for (uint256 i = 0; i < _count - 1; i++) {
            _withdrawSomeFromPool(lockedNfts[i].token_id, uint128(lockedNfts[i].liquidity));
        }

        LockedNFT memory lastNFT = lockedNfts[_count - 1];

        if (_sum > _liquidity) {
            uint128 _withdraw = uint128(uint256(lastNFT.liquidity).sub(_sum.sub(_liquidity)));
            require(_withdraw <= lastNFT.liquidity, "math error");
            _withdrawSomeFromPool(lastNFT.token_id, _withdraw);

            nftManager.safeTransferFrom(address(this), strategyProxy, lastNFT.token_id);
            IStrategyProxy(strategyProxy).depositV3(
                frax_dai_gauge,
                lastNFT.token_id,
                IFraxGaugeBase(frax_dai_gauge).lock_time_min()
            );
        } else {
            _withdrawSomeFromPool(lastNFT.token_id, uint128(lastNFT.liquidity));
        }

        console.log("   [withdrawSome] token0 Balance after burn => ", token0.balanceOf(address(this)));
        console.log("   [withdrawSome] token1 Balance after burn => ", token1.balanceOf(address(this)));

        return (token0.balanceOf(address(this)).sub(_balances[0]), token1.balanceOf(address(this)).sub(_balances[1]));
    }
}
