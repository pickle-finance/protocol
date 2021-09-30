// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeUsdceJoeLp is StrategyJoeFarmBase {
    uint256 public avax_joe_poolId = 58;
    address public joe_usdce_joe_lp =
        0x67926d973cD8eE876aD210fAaf7DFfA99E414aCf;
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_joe_poolId,
            joe_usdce_joe_lp,
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
            IERC20(joe).safeApprove(joeRouter, _amount);

            _swapTraderJoe(joe, usdce, _amount);
        }

        // Adds in liquidity for JOE/USDCE
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));

        _joe = IERC20(joe).balanceOf(address(this));

        if (_usdce > 0 && _joe > 0) {
            IERC20(usdce).safeApprove(joeRouter, 0);
            IERC20(usdce).safeApprove(joeRouter, _usdce);

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);

            IJoeRouter(joeRouter).addLiquidity(
                usdce,
                joe,
                _usdce,
                _joe,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(usdce).transfer(
                IController(controller).treasury(),
                IERC20(usdce).balanceOf(address(this))
            );
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                IERC20(joe).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeUsdceJoeLp";
    }
}
