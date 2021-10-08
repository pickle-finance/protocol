// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeMaiUsdcELp is StrategyJoeFarmBase {
    uint256 public avax_joe_poolId = 47;

    address public joe_mai_usdce_lp =
        0x58f75d7745ec383491053947Cd2AE6Ee7fc8B8f8;
    address public mai = 0x3B55E45fD6bd7d4724F5c47E0d1bCaEdd059263e;
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
            joe_mai_usdce_lp,
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

            _swapTraderJoe(joe, mai, _amount);
            _swapTraderJoe(joe, usdce, _amount);
        }

        // Adds in liquidity for USDT.e/WBTC.e
        uint256 _mai = IERC20(mai).balanceOf(address(this));
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));

        if (_mai > 0 && _joe > 0) {
            IERC20(mai).safeApprove(joeRouter, 0);
            IERC20(mai).safeApprove(joeRouter, _mai);

            IERC20(usdce).safeApprove(joeRouter, 0);
            IERC20(usdce).safeApprove(joeRouter, _usdce);

            IJoeRouter(joeRouter).addLiquidity(
                mai,
                usdce,
                _mai,
                _usdce,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(mai).transfer(
                IController(controller).treasury(),
                IERC20(mai).balanceOf(address(this))
            );
            IERC20(usdce).safeTransfer(
                IController(controller).treasury(),
                IERC20(usdce).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeMaiUsdcELp";
    }
}
