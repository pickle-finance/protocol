// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxTsdLp is StrategyJoeFarmBase {
    uint256 public avax_tsd_poolId = 63;

    address public joe_avax_tsd_lp = 0x2d16af2D7f1edB4bC5DBAdF3ffF04670B4BcD0BB;
    address public tsd = 0x4fbf0429599460D327BD5F55625E30E4fC066095;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_tsd_poolId,
            joe_avax_tsd_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But AVAX is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV2).deposit(poolId, 0);

        uint256 _joe = IERC20(joe).balanceOf(address(this));
        if (_joe > 0) {
            // 10% is sent to treasury
            uint256 _keep = _joe.mul(keep).div(keepMax);
            uint256 _amount = _joe.sub(_keep).div(2);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keep));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, tsd, _amount);
        }

        // Adds in liquidity for AVAX/TSD
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _tsd = IERC20(tsd).balanceOf(address(this));

        if (_wavax > 0 && _tsd > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(tsd).safeApprove(joeRouter, 0);
            IERC20(tsd).safeApprove(joeRouter, _tsd);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                tsd,
                _wavax,
                _tsd,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                IERC20(wavax).balanceOf(address(this))
            );
            IERC20(tsd).safeTransfer(
                IController(controller).treasury(),
                IERC20(tsd).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxTsdLp";
    }
}
