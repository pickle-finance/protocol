// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance-staker.sol";

contract StrategyUsdcEthUniV3StakerArbi is StrategyRebalanceStakerUniV3 {
    address public usdc_eth_pool = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
    address[] public rewardTokens = [address(token0), address(token1)];

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceStakerUniV3(usdc_eth_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock)
    {
        univ3_staker = 0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d;

        key = IUniswapV3Staker.IncentiveKey({
            rewardToken: IERC20Minimal(rewardToken),
            pool: IUniswapV3Pool(usdc_eth_pool),
            startTime: 1633694400,
            endTime: 1638878400,
            refundee: 0xDAEada3d210D2f45874724BeEa03C7d4BBD41674 // rbn multisig
        });

        rewardToken = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyUsdcEthUniV3Arbi";
    }

    //This function assumes staking rewards is one of the deposited tokens.
    function harvest() public override onlyBenevolent {
        if (isStakingActive()) {
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
            IUniswapV3Staker(univ3_staker).claimReward(IERC20Minimal(rewardToken), address(this), 0);
            IUniswapV3Staker(univ3_staker).withdrawToken(tokenId, address(this), bytes(""));
        }

        nftManager.collect(
            IUniswapV3PositionsNFT.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        nftManager.sweepToken(address(token0), 0, address(this));
        nftManager.sweepToken(address(token1), 0, address(this));

        balanceProportion(tick_lower, tick_upper);

        _distributePerformanceFeesAndDeposit();

        redeposit();

        emit Harvested(tokenId);
    }

    //This assumes rewardToken == token0
    function getHarvestable() public view returns (uint256, uint256) {
        //This will only update when someone mint/burn/pokes the pool.
        (, , , , , , , , , , uint128 _owed0, uint128 _owed1) = nftManager.positions(tokenId);
        uint256 _stakingRewards = IUniswapV3Staker(univ3_staker).rewards(key.rewardToken, address(this));
        return (uint256(_owed0 + _stakingRewards), uint256(_owed1));
    }

    //Need to call this at end of Liquidity Mining This assumes rewardToken is token0 or token1
    function endOfLM() external onlyBenevolent {
      require(block.timestamp > key.endTime, "Not End of LM");

      uint256 _liqAmt0 = token0.balanceOf(address(this));
      uint256 _liqAmt1 = token1.balanceOf(address(this));
      // claim entire rewards
      IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
      IUniswapV3Staker(univ3_staker).claimReward(IERC20Minimal(rewardToken), address(this), 0);
      IUniswapV3Staker(univ3_staker).withdrawToken(tokenId, address(this), bytes(""));

      _distributePerformanceFees(
          token0.balanceOf(address(this)).sub(_liqAmt0),
          token1.balanceOf(address(this)).sub(_liqAmt1)
      );
    }

    //This assumes rewardToken == (token0 || token1)
    function rebalance() external onlyBenevolent returns (uint256 _tokenId) {
        if (isStakingActive()) {
            // If NFT is held by staker, then withdraw
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);

            // claim entire rewards
            IUniswapV3Staker(univ3_staker).claimReward(IERC20Minimal(rewardToken), address(this), 0);
            IUniswapV3Staker(univ3_staker).withdrawToken(tokenId, address(this), bytes(""));
        }

        (, , , , , , , uint256 _liquidity, , , , ) = nftManager.positions(tokenId);
        (uint256 _liqAmt0, uint256 _liqAmt1) = nftManager.decreaseLiquidity(
            IUniswapV3PositionsNFT.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: uint128(_liquidity),
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 300
            })
        );

        // This has to be done after DecreaseLiquidity to collect the tokens we
        // decreased and the fees at the same time.
        nftManager.collect(
            IUniswapV3PositionsNFT.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        nftManager.sweepToken(address(token0), 0, address(this));
        nftManager.sweepToken(address(token1), 0, address(this));
        nftManager.burn(tokenId);

        _distributePerformanceFees(
            token0.balanceOf(address(this)).sub(_liqAmt0),
            token1.balanceOf(address(this)).sub(_liqAmt1)
        );

        (int24 _tickLower, int24 _tickUpper) = determineTicks();
        balanceProportion(_tickLower, _tickUpper);
        //Need to do this again after the swap to cover any slippage.
        uint256 _amount0Desired = token0.balanceOf(address(this));
        uint256 _amount1Desired = token1.balanceOf(address(this));

        (_tokenId, , , ) = nftManager.mint(
            IUniswapV3PositionsNFT.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: pool.fee(),
                tickLower: _tickLower,
                tickUpper: _tickUpper,
                amount0Desired: _amount0Desired,
                amount1Desired: _amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 300
            })
        );

        //Record updated information.
        tokenId = _tokenId;
        tick_lower = _tickLower;
        tick_upper = _tickUpper;

        if (isStakingActive()) {
            nftManager.safeTransferFrom(address(this), univ3_staker, tokenId);
            IUniswapV3Staker(univ3_staker).stakeToken(key, tokenId);
        }

        emit Rebalanced(tokenId, _tickLower, _tickUpper);
    }
}
