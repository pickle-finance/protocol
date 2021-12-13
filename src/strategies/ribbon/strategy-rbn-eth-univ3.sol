// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-base.sol";
import "../../interfaces//univ3/IUniswapV3Staker.sol";
import "../../interfaces/weth.sol";
import "../../lib/univ3/PoolActions.sol";
import "../../lib/univ3/PoolVariables.sol";
import "hardhat/console.sol";

contract StrategyRbnEthUniV3 is StrategyUniV3Base {
    address public rbn_eth_pool = 0x94981F69F7483AF3ae218CbfE65233cC3c60d93a;
    address public univ3_staker = 0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d;

    address public constant rbn = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;
    uint256 public tokenId;

    IUniswapV3Staker.IncentiveKey key =
        IUniswapV3Staker.IncentiveKey({
            rewardToken: IERC20Minimal(rbn),
            pool: IUniswapV3Pool(rbn_eth_pool),
            startTime: 1633694400,
            endTime: 1638878400,
            refundee: 0xDAEada3d210D2f45874724BeEa03C7d4BBD41674 // rbn multisig
        });

    address[] public rewardTokens = [weth, rbn];

    bool public stakingActive = true;

    event InitialDeposited(uint256 tokenId);
    event harvested(uint256 tokenId);
    event deposited(uint256 tokenId, uint256 rbnBalance, uint256 wethBalance);
    event withdrawn(uint256 tokenId, uint256 _liquidity);
    event rebalanced(uint256 tokenId, int24 _tickLower, int24 _tickUpper);

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyUniV3Base(rbn_eth_pool, -887200, 887200, _governance, _strategist, _controller, _timelock) {
        token0.safeApprove(address(nftManager), uint256(-1));
        token1.safeApprove(address(nftManager), uint256(-1));
        nftManager.setApprovalForAll(univ3_staker, true);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyRbnEthUniV3";
    }

    function isStakingActive() internal returns (bool stakingActive) {
        return (block.timestamp >= key.startTime && block.timestamp < key.endTime) ? true : false;
    }

    function depositInitial() public returns (uint256 _tokenId) {
        require(msg.sender == governance || msg.sender == strategist, "not authorized");
        require(tokenId == 0, "token already set");

        uint256 _token0 = token0.balanceOf(address(this)); // rbn
        uint256 _token1 = token1.balanceOf(address(this)); // weth

        (_tokenId, , , ) = nftManager.mint(
            IUniswapV3PositionsNFT.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: pool.fee(),
                tickLower: tick_lower,
                tickUpper: tick_upper,
                amount0Desired: _token0,
                amount1Desired: _token1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 300
            })
        );

        nftManager.sweepToken(weth, 0, address(this));
        nftManager.sweepToken(rbn, 0, address(this));

        // Record tokenId
        tokenId = _tokenId;

        // Deposit + stake in Uni v3 staker only if staking is active.
        if (isStakingActive()) {
            nftManager.safeTransferFrom(address(this), univ3_staker, tokenId);
            IUniswapV3Staker(univ3_staker).stakeToken(key, tokenId);
        }

        emit InitialDeposited(tokenId);
    }

    function harvest() public override onlyBenevolent {
        if (isStakingActive()) {
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
            IUniswapV3Staker(univ3_staker).claimReward(IERC20Minimal(rbn), address(this), 0);
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

        balanceProportion(tick_lower, tick_upper);

        nftManager.sweepToken(weth, 0, address(this));
        nftManager.sweepToken(rbn, 0, address(this));

        uint256 _rbn = IERC20(token0).balanceOf(address(this));
        uint256 _weth = IERC20(token1).balanceOf(address(this));

        if (_rbn > 0 && _weth > 0) {
            _distributePerformanceFeesAndDeposit();
        }

        emit harvested(tokenId);
    }

    function liquidityOfPool() public view override returns (uint256) {
        (, , , , , , , uint256 _liquidity, , , , ) = nftManager.positions(tokenId);
        return _liquidity;
    }

    function getHarvestable() public view returns (uint256, uint256) {}

    // **** Setters ****

    function deposit() public override {
        // If NFT is held by staker, then withdraw
        if (nftManager.ownerOf(tokenId) != address(this) && isStakingActive()) {
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
            IUniswapV3Staker(univ3_staker).withdrawToken(tokenId, address(this), bytes(""));
        }

        uint256 _token0 = token0.balanceOf(address(this)); // rbn
        uint256 _token1 = token1.balanceOf(address(this)); // weth

        if (_token0 > 0 && _token1 > 0) {
            nftManager.increaseLiquidity(
                IUniswapV3PositionsNFT.IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: _token0,
                    amount1Desired: _token1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 300
                })
            );
        }
        redeposit();

        emit deposited(tokenId, _token0, _token1);
    }

    // Deposit + stake in Uni v3 staker
    function redeposit() internal {
        if (isStakingActive()) {
            nftManager.safeTransferFrom(address(this), univ3_staker, tokenId);
            IUniswapV3Staker(univ3_staker).stakeToken(key, tokenId);
        }
    }

    function _withdrawSome(uint256 _liquidity) internal override returns (uint256, uint256) {
        if (_liquidity == 0) return (0, 0);
        if (isStakingActive()) {
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
            IUniswapV3Staker(univ3_staker).withdrawToken(tokenId, address(this), bytes(""));
        }

        (uint256 _a0Expect, uint256 _a1Expect) = pool.amountsForLiquidity(uint128(_liquidity), tick_lower, tick_upper);
        (uint256 amount0, uint256 amount1) = nftManager.decreaseLiquidity(
            IUniswapV3PositionsNFT.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: uint128(_liquidity),
                amount0Min: _a0Expect,
                amount1Min: _a1Expect,
                deadline: block.timestamp + 300
            })
        );

       //Only collect decreasedLiquidity, not trading fees.
        nftManager.collect(
            IUniswapV3PositionsNFT.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: uint128(amount0),
                amount1Max: uint128(amount1)
            })
        );

        return (amount0, amount1);
    }

    // Override base withdraw function to redeposit
    function withdraw(uint256 _liquidity) external override returns (uint256 a0, uint256 a1) {
        require(msg.sender == controller, "!controller");
        (a0, a1) = _withdrawSome(_liquidity);

        address _jar = IControllerV2(controller).jars(address(pool));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds

        token0.safeTransfer(_jar, a0);
        token1.safeTransfer(_jar, a1);

        redeposit();

        emit withdrawn(tokenId, _liquidity);
    }

    function rebalance(int24 _tickLower, int24 _tickUpper) external returns (uint256 _tokenId) {
        require(msg.sender == governance, "!governance");
        require(_tickLower % key.pool.tickSpacing() == 0, "_tickLower needs to be a multiple of tickSpacing");
        require(_tickUpper % key.pool.tickSpacing() == 0, "_tickUpper needs to be a multiple of tickSpacing");
        PoolVariables.checkRange(_tickLower, _tickUpper);

        if (isStakingActive()) {
            // If NFT is held by staker, then withdraw
            IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);

            // claim entire rewards
            IUniswapV3Staker(univ3_staker).claimReward(IERC20Minimal(rbn), address(this), 0);
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

        nftManager.sweepToken(weth, 0, address(this));
        nftManager.sweepToken(rbn, 0, address(this));
        nftManager.burn(tokenId);

        _distributePerformanceFees(
            token0.balanceOf(address(this)).sub(_liqAmt0),
            token1.balanceOf(address(this)).sub(_liqAmt1)
        );

        balanceProportion(_tickLower, _tickUpper);

        //Need to do this again after the swap to cover any slippage.
        uint256 _amount0Desired = token0.balanceOf(address(this)); //rbn
        uint256 _amount1Desired = token1.balanceOf(address(this)); //weth

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

        emit rebalanced(tokenId, _tickLower, _tickUpper);
    }

    function balanceProportion(int24 _tickLower, int24 _tickUpper) internal {
        PoolVariables.Info memory _cache;

        _cache.amount0Desired = token0.balanceOf(address(this)); //rbn
        _cache.amount1Desired = token1.balanceOf(address(this)); //weth

        //Get Max Liquidity for Amounts we own.
        _cache.liquidity = pool.liquidityForAmounts(_cache.amount0Desired, _cache.amount1Desired, _tickLower, _tickUpper);

        //Get correct amounts of each token for the liquidity we have.
        (_cache.amount0, _cache.amount1) = pool.amountsForLiquidity(_cache.liquidity, _tickLower, _tickUpper);

        //Determine Trade Direction
        bool _zeroForOne = PoolVariables.amountsDirection(
            _cache.amount0Desired,
            _cache.amount1Desired,
            _cache.amount0,
            _cache.amount1
        );

        //Determine Amount to swap
        uint256 _amountSpecified = _zeroForOne
            ? (_cache.amount0Desired.sub(_cache.amount0).div(2))
            : (_cache.amount1Desired.sub(_cache.amount1).div(2));

        if (_amountSpecified > 0) {

            //Determine Token to swap
            address _inputToken = _zeroForOne ? address(token0) : address(token1);

            IERC20(_inputToken).safeApprove(univ3Router, 0);
            IERC20(_inputToken).safeApprove(univ3Router, _amountSpecified);

            //Swap the token imbalanced
            ISwapRouter(univ3Router).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _inputToken,
                    tokenOut: _zeroForOne ? address(token1) : address(token0),
                    fee: pool.fee(),
                    recipient: address(this),
                    deadline: block.timestamp + 300,
                    amountIn: _amountSpecified,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        }
    }
}
