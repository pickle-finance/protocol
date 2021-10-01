// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxElkLp is StrategyJoeFarmBase {

    uint256 public avax_elk_poolId = 12;

    address public joe_avax_elk_lp = 0x88D000E853d03E7D59CE602dff736Dc39aD118fb;
    address public elk = 0xE1C110E1B1b4A1deD0cAf3E42BfBdbB7b5d7cE1C;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_elk_poolId,
            joe_avax_elk_lp,
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
            _takeFeeJoeToSnob(_keep);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keep));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, elk, _amount);
        }

        // Adds in liquidity for AVAX/ELK
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _elk = IERC20(elk).balanceOf(address(this));

        if (_wavax > 0 && _elk > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(elk).safeApprove(joeRouter, 0);
            IERC20(elk).safeApprove(joeRouter, _elk);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                elk,
                _wavax,
                _elk,
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
            IERC20(elk).safeTransfer(
                IController(controller).treasury(),
                IERC20(elk).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxElkLp";
    }
}
