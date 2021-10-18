// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-base.sol";
import "../../interfaces//univ3/IUniswapV3Staker.sol";
import "../../interfaces/weth.sol";

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

    function depositInitial() public returns (uint256) {
        require(msg.sender == governance || msg.sender == strategist, "not authorized");
        require(tokenId == 0, "token already set");

        uint256 _token0 = token0.balanceOf(address(this)); // rbn
        uint256 _token1 = token1.balanceOf(address(this)); // weth

        (uint256 _tokenId, , , ) = nftManager.mint(
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

        // Deposit in Uni v3 staker
        IERC721(address(nftManager)).safeTransferFrom(
            address(this),
            univ3_staker,
            tokenId,
            abi.encodePacked(
                IUniswapV3Staker.IncentiveKey(key.rewardToken, key.pool, key.startTime, key.endTime, key.refundee)
            )
        );
    }

    function harvest() public override onlyBenevolent {
        IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
        IUniswapV3Staker(univ3_staker).claimReward(IERC20Minimal(rbn), address(this), 0);
        IUniswapV3Staker(univ3_staker).withdrawToken(tokenId, address(this), bytes(""));

        uint256 _rbn = IERC20(rbn).balanceOf(address(this));
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        uint256 _ratio = getProportion();
        uint256 _amount1Desired = (_weth.add(_rbn)).mul(_ratio).div(_ratio.add(1e18));
        uint256 _amount;
        address from;
        address to;

        if (_amount1Desired < _rbn) {
            _amount = _rbn.sub(_amount1Desired);
            from = rbn;
            to = weth;
        } else {
            _amount = _amount1Desired.sub(_rbn);
            from = weth;
            to = rbn;
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
        nftManager.sweepToken(weth, 0, address(this));
        nftManager.sweepToken(rbn, 0, address(this));

        _distributePerformanceFeesAndDeposit();
    }

    function liquidityOfPool() public view override returns (uint256) {
        (, , , , , , , uint256 _liquidity, , , , ) = nftManager.positions(tokenId);
        return _liquidity;
    }

    function getHarvestable() public view returns (uint256, uint256) {}

    // **** Setters ****

    function deposit() public override {
        IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);

        uint256 _token0 = token0.balanceOf(address(this)); // rbn
        uint256 _token1 = token1.balanceOf(address(this)); // weth

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
        nftManager.safeTransferFrom(
            address(this),
            univ3_staker,
            tokenId,
            abi.encodePacked(
                IUniswapV3Staker.IncentiveKey(key.rewardToken, key.pool, key.startTime, key.endTime, key.refundee)
            )
        );
    }

    function _withdrawSome(uint256 _liquidity) internal override returns (uint256, uint256) {
        if (_liquidity == 0) return (0, 0);
        uint256 amount0;
        uint256 amount1;
        IUniswapV3Staker(univ3_staker).unstakeToken(key, tokenId);
        IUniswapV3Staker(univ3_staker).claimReward(IERC20Minimal(rbn), address(this), 0);
        IUniswapV3Staker(univ3_staker).withdrawToken(tokenId, address(this), bytes(""));

        (uint256 _a0Expect, uint256 _a1Expect) = pool.amountsForLiquidity(uint128(_liquidity), tick_lower, tick_upper);
        nftManager.decreaseLiquidity(
            IUniswapV3PositionsNFT.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: uint128(_liquidity),
                amount0Min: _a0Expect,
                amount1Min: _a1Expect,
                deadline: block.timestamp + 300
            })
        );

        (uint256 _a0, uint256 _a1) = nftManager.collect(
            IUniswapV3PositionsNFT.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
        amount0 = amount0.add(_a0);
        amount1 = amount1.add(_a1);
        return (amount0, amount1);
    }
}
