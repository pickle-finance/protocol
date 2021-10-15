// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-base.sol";
import "../../interfaces//univ3/IUniswapV3Staker.sol";

contract StrategyRbnEthUniV3 is StrategyUniV3Base {

    address public rbn_eth_pool = 0x94981F69F7483AF3ae218CbfE65233cC3c60d93a;
    address public univ3_staker = 0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d;

    address public constant rbn = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;
  
    address[] public rewardTokens = [weth, rbn];

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyUniV3Base(rbn_eth_pool, -887200, 887200, _governance, _strategist, _controller, _timelock) {}

    function getName() external pure override returns (string memory) {
        return "StrategyRbnEthUniV3";
    }

    function harvest() public override onlyBenevolent {
        IUniswapV3Staker(univ3_staker).claimReward(rbn, address(this), 0);

        uint256 _rbn = IERC20(rbn).balanceOf(address(this));

        uint256 _ratio = getProportion();
        uint256 _amount = _rbn.mul(_ratio).div(_ratio.add(1e18));

        IERC20(from).safeApprove(univ3Router, 0);
        IERC20(from).safeApprove(univ3Router, _amount);

        ISwapRouter(univ3Router).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: rbn,
                tokenOut: weth,
                fee: pool.fee(),
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: _amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        _distributePerformanceFeesAndDeposit();
    }

    function liquidityOfPool() public view override returns (uint256) {
        return IStrategyProxy(strategyProxy).balanceOf(frax_dai_gauge);
    }

    function getHarvestable() public view returns (uint256, uint256) {}

    // **** Setters ****

    function deposit() public override {
        (uint256 _tokenId, ) = _wrapAllToNFT();
        nftManager.setApprovalForAll(univ3_staker, true);

        IUniswapV3Staker.IncentiveKey memory key;
        key.rewardToken = rbn;
        key.pool = rbn_eth_pool;
        key.startTime = 1633694400;
        key.endTime = 1638878400;
        key.refundee = address(this);

        IUniswapV3Staker(univ3_staker).stakeToken(key, _tokenId);
    }

    function _withdrawSomeFromPool(uint256 _tokenId, uint128 _liquidity)
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        if (_tokenId == 0 || _liquidity == 0) return (0, 0);
        (uint256 _a0Expect, uint256 _a1Expect) = pool.amountsForLiquidity(_liquidity, tick_lower, tick_upper);
        nftManager.decreaseLiquidity(
            IUniswapV3PositionsNFT.DecreaseLiquidityParams({
                tokenId: _tokenId,
                liquidity: _liquidity,
                amount0Min: _a0Expect,
                amount1Min: _a1Expect,
                deadline: block.timestamp + 300
            })
        );

        (uint256 _a0, uint256 _a1) = nftManager.collect(
            IUniswapV3PositionsNFT.CollectParams({
                tokenId: _tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
        amount0 = amount0.add(_a0);
        amount1 = amount1.add(_a1);
    }

    function _withdrawSome(uint256 _liquidity) internal override returns (uint256, uint256) {
        LockedNFT[] memory lockedNfts = IStrategyProxy(strategyProxy).lockedNFTsOf(frax_dai_gauge);
        uint256[2] memory _amounts;

        uint256 _sum;
        uint256 _count;

        for (uint256 i = 0; i < lockedNfts.length; i++) {
            if (lockedNfts[i].token_id == 0 || lockedNfts[i].liquidity == 0) {
                _count++;
                continue;
            }
            _sum = _sum.add(
                IStrategyProxy(strategyProxy).withdrawV3(frax_dai_gauge, lockedNfts[i].token_id, rewardTokens)
            );
            _count++;
            if (_sum >= _liquidity) break;
        }

        require(_sum >= _liquidity, "insufficient liquidity");

        for (uint256 i = 0; i < _count - 1; i++) {
            (uint256 _a0, uint256 _a1) = _withdrawSomeFromPool(
                lockedNfts[i].token_id,
                uint128(lockedNfts[i].liquidity)
            );
            _amounts[0] = _amounts[0].add(_a0);
            _amounts[1] = _amounts[1].add(_a1);
        }

        LockedNFT memory lastNFT = lockedNfts[_count - 1];

        if (_sum > _liquidity) {
            uint128 _withdraw = uint128(uint256(lastNFT.liquidity).sub(_sum.sub(_liquidity)));
            require(_withdraw <= lastNFT.liquidity, "math error");

            (uint256 _a0, uint256 _a1) = _withdrawSomeFromPool(lastNFT.token_id, _withdraw);
            _amounts[0] = _amounts[0].add(_a0);
            _amounts[1] = _amounts[1].add(_a1);

            nftManager.safeTransferFrom(address(this), strategyProxy, lastNFT.token_id);
            IStrategyProxy(strategyProxy).depositV3(
                frax_dai_gauge,
                lastNFT.token_id,
                IFraxGaugeBase(frax_dai_gauge).lock_time_min()
            );
        } else {
            (uint256 _a0, uint256 _a1) = _withdrawSomeFromPool(lastNFT.token_id, uint128(lastNFT.liquidity));
            _amounts[0] = _amounts[0].add(_a0);
            _amounts[1] = _amounts[1].add(_a1);
        }

        return (_amounts[0], _amounts[1]);
    }
}
