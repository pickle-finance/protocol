// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxUsdtLp is StrategyJoeFarmBase {

    uint256 public avax_usdt_poolId = 2;

    address public joe_avax_usdt_lp = 0xE4B9865C0866346BA3613eC122040A365637fB46;
    address public usdt = 0xde3A24028580884448a5397872046a019649b084;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_usdt_poolId,
            joe_avax_usdt_lp,
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
            _swapTraderJoe(joe, usdt, _amount);
        }

        // Adds in liquidity for AVAX/USDT
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _usdt = IERC20(usdt).balanceOf(address(this));

        if (_wavax > 0 && _usdt > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(usdt).safeApprove(joeRouter, 0);
            IERC20(usdt).safeApprove(joeRouter, _usdt);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                usdt,
                _wavax,
                _usdt,
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
            IERC20(usdt).safeTransfer(
                IController(controller).treasury(),
                IERC20(usdt).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxUsdtLp";
    }
}
