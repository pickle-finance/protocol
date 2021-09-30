// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxTeddyLp is StrategyJoeFarmBase {
    uint256 public avax_teddy_poolId = 64;

    address public joe_avax_teddy_lp =
        0x91f0963873bbcA2e58d21bB0941c0D859Db3ca31;
    address public teddy = 0x094bd7B2D99711A1486FB94d4395801C6d0fdDcC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_teddy_poolId,
            joe_avax_teddy_lp,
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
            uint256 _keepJOE = _joe.mul(keepJOE).div(keepJOEMax);
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                _keepJOE
            );
            uint256 _amount = _joe.sub(_keepJOE).div(2);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keepJOE));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, teddy, _amount);
        }

        // Adds in liquidity for AVAX/TEDDY
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _teddy = IERC20(teddy).balanceOf(address(this));

        if (_wavax > 0 && _teddy > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(teddy).safeApprove(joeRouter, 0);
            IERC20(teddy).safeApprove(joeRouter, _teddy);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                teddy,
                _wavax,
                _teddy,
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
            IERC20(teddy).safeTransfer(
                IController(controller).treasury(),
                IERC20(teddy).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxTeddyLp";
    }
}
