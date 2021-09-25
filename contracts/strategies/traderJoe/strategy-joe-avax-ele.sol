// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxEleLp is StrategyJoeFarmBase {

    uint256 public avax_ele_poolId = 42;

    address public joe_avax_ele_lp = 0x0A6f6F504245BdC36b47d72d8718c09D6c0461de;
    address public ele = 0xAcD7B3D9c10e97d0efA418903C0c7669E702E4C0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_ele_poolId,
            joe_avax_ele_lp,
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
            _takeFeeJoeToSnob(_keepJOE);
            
            uint256 _amount = _joe.sub(_keepJOE).div(2);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keepJOE));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, ele, _amount);
        }

        // Adds in liquidity for AVAX/WBTC
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _ele = IERC20(ele).balanceOf(address(this));

        if (_wavax > 0 && _ele > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(ele).safeApprove(joeRouter, 0);
            IERC20(ele).safeApprove(joeRouter, _ele);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                ele,
                _wavax,
                _ele,
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
            IERC20(ele).safeTransfer(
                IController(controller).treasury(),
                IERC20(ele).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxEleLp";
    }
}
