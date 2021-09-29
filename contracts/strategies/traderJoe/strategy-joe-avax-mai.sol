// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxMaiLp is StrategyJoeFarmBase {
    uint256 public avax_mai_poolId = 57;

    address public joe_avax_mai_lp = 0xD6d03fe131dB3dE3aF5E6326036BaC4C1Cf8C80d;
    address public mai = 0x3B55E45fD6bd7d4724F5c47E0d1bCaEdd059263e;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_mai_poolId,
            joe_avax_mai_lp,
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
            _swapTraderJoe(joe, mai, _amount);
        }

        // Adds in liquidity for AVAX/MAI
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _mai = IERC20(mai).balanceOf(address(this));

        if (_wavax > 0 && _mai > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(mai).safeApprove(joeRouter, 0);
            IERC20(mai).safeApprove(joeRouter, _mai);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                mai,
                _wavax,
                _mai,
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
            IERC20(mai).safeTransfer(
                IController(controller).treasury(),
                IERC20(mai).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxMaiLp";
    }
}
