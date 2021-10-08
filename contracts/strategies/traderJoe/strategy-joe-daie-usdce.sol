// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeDaiEUsdcELp is StrategyJoeFarmBase {

    uint256 public avax_joe_poolId = 40;

    address public joe_daie_usdce_lp = 0x63ABE32d0Ee76C05a11838722A63e012008416E6;
    address public daie = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
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
            joe_daie_usdce_lp,
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

            _swapTraderJoe(joe, daie, _amount);
            _swapTraderJoe(joe, usdce, _amount);
        }

        // Adds in liquidity for DAI.e/USDC.e
        uint256 _daie = IERC20(daie).balanceOf(address(this));
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));

        if (_daie > 0 && _joe > 0) {
            IERC20(daie).safeApprove(joeRouter, 0);
            IERC20(daie).safeApprove(joeRouter, _daie);

            IERC20(usdce).safeApprove(joeRouter, 0);
            IERC20(usdce).safeApprove(joeRouter, _usdce);

            IJoeRouter(joeRouter).addLiquidity(
                daie,
                usdce,
                _daie,
                _usdce,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(daie).transfer(
                IController(controller).treasury(),
                IERC20(daie).balanceOf(address(this))
            );
            IERC20(usdce).safeTransfer(
                IController(controller).treasury(),
                IERC20(usdce).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeUsdtEUsdcELp";
    }
}
