// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../../interfaces/curve.sol";

import "../strategy-base.sol";

interface SwapFlashLoan {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external;
}

contract StrategySaddleD4v2 is StrategyBase {
    address public gauge = 0x702c1b8Ec3A77009D5898e18DA8F8959B6dF2093;
    address public minter = 0x358fE82370a1B9aDaE2E3ad69D6cF9e503c96018;
    address public saddle_d4lp = 0xd48cF4D7FB0824CC8bAe055dF3092584d0a1726A;

    address private frax = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address private sdl = 0xf1Dc500FdE233A4055e25e5BbF516372BC4F6871; // reward token

    address private flashLoan = 0xC69DDcd4DFeF25D8a793241834d4cc4b3668EAD6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(saddle_d4lp, _governance, _strategist, _controller, _timelock) {
        IERC20(sdl).safeApprove(sushiRouter, uint256(-1));
        IERC20(weth).safeApprove(univ3Router, uint256(-1));
        IERC20(frax).safeApprove(flashLoan, uint256(-1));
        IERC20(want).safeApprove(gauge, uint256(-1));
    }

    function getName() external pure override returns (string memory) {
        return "StrategySaddleD4v2";
    }

    function balanceOfPool() public view override returns (uint256) {
        return ICurveGauge(gauge).balanceOf(address(this));
    }

    // callStatic on this
    function getHarvestable() public returns (uint256) {
        return ICurveGauge(gauge).claimable_tokens(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            ICurveGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        ICurveGauge(gauge).withdraw(_amount);
        return _amount;
    }

    function harvest() public override {
        ICurveGauge(gauge).claim_rewards(address(this));
        ICurveMintr(minter).mint(address(gauge));

        uint256 _sdl = IERC20(sdl).balanceOf(address(this));
        if (_sdl > 0) {
            uint256 _keepSdl = _sdl.mul(performanceTreasuryFee).div(performanceTreasuryMax);
            IERC20(sdl).safeTransfer(IController(controller).treasury(), _keepSdl);

            _sdl = _sdl.sub(_keepSdl);

            // Step 1: trade all SDL for WETH on Sushi
            _swapSushiswap(sdl, weth, _sdl);

            // Step 2: trade all WETH for FRAX on Uniswap V3
            uint256 _weth = IERC20(weth).balanceOf(address(this));

            ISwapRouter(univ3Router).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: weth,
                    tokenOut: frax,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: _weth,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );

            // Step 3: Add frax liquidity and deposit
            uint256[] memory amounts = new uint256[](4);
            amounts[2] = IERC20(frax).balanceOf(address(this));
            SwapFlashLoan(flashLoan).addLiquidity(amounts, 0, block.timestamp);

            deposit();
        }
    }
}
