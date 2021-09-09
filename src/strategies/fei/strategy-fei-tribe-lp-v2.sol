// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-fei-farm-base-v2.sol";

contract StrategyFeiTribeLpV2 is StrategyFeiFarmBaseV2 {
    uint256 public fei_tribe_poolId = 0;
    address
        public uni_fei_tribe_lp = 0x9928e4046d7c6513326cCeA028cD3e7a91c7590A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFeiFarmBaseV2(
            fei_tribe_poolId,
            uni_fei_tribe_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        deposit();
        IFeichefV2(feiChef).harvest(poolId, address(this));

        uint256 _tribe = IERC20(tribe).balanceOf(address(this));
        if (_tribe > 0) {
            uint256 _amount = _tribe.div(2);
            IERC20(tribe).safeApprove(univ2Router2, 0);
            IERC20(tribe).safeApprove(univ2Router2, _amount);
            _swapUniswap(tribe, fei, _amount);
        }

        // Adds in liquidity for FEI/TRIBE
        uint256 _fei = IERC20(fei).balanceOf(address(this));
        _tribe = IERC20(tribe).balanceOf(address(this));

        if (_fei > 0 && _tribe > 0) {
            IERC20(fei).approve(univ2Router2, 0);
            IERC20(fei).approve(univ2Router2, _fei);

            IERC20(tribe).approve(univ2Router2, 0);
            IERC20(tribe).approve(univ2Router2, _tribe);

            UniswapRouterV2(univ2Router2).addLiquidity(
                fei,
                tribe,
                _fei,
                _tribe,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(fei).safeTransfer(
                IController(controller).treasury(),
                IERC20(fei).balanceOf(address(this))
            );
            IERC20(tribe).safeTransfer(
                IController(controller).treasury(),
                IERC20(tribe).balanceOf(address(this))
            );
        }

        // We want to get back FEI-TRIBE LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyFeiTribeLpV2";
    }
}
