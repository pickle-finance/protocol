// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxBifiLp is StrategyJoeFarmBase {
    uint256 public avax_bifi_poolId = 53;

    address public joe_avax_bifi_lp =
        0x361221991B3B6282fF3a62Bc874d018bfAF1f8C8;
    address public bifi = 0xd6070ae98b8069de6B494332d1A1a81B6179D960;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_bifi_poolId,
            joe_avax_bifi_lp,
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
            _swapTraderJoe(joe, bifi, _amount);
        }

        // Adds in liquidity for AVAX/BIFI
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _bifi = IERC20(bifi).balanceOf(address(this));

        if (_wavax > 0 && _bifi > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(bifi).safeApprove(joeRouter, 0);
            IERC20(bifi).safeApprove(joeRouter, _bifi);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                bifi,
                _wavax,
                _bifi,
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
            IERC20(bifi).safeTransfer(
                IController(controller).treasury(),
                IERC20(bifi).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxBifiLp";
    }
}
