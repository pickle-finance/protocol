// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxAaveeLp is StrategyJoeFarmBase {
    uint256 public avax_aavee_poolId = 62;

    address public joe_avax_aavee_lp =
        0xc3e6D9f7a3A5E3e223356383C7C055Ee3F26A34F;
    address public aavee = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_aavee_poolId,
            joe_avax_aavee_lp,
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
            /// 10% is sent to treasury
            uint256 _keep = _joe.mul(keep).div(keepMax);
            uint256 _amount = _joe.sub(_keep).div(2);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keep));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, aavee, _amount);
        }

        // Adds in liquidity for AVAX/AAVE.E
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _aavee = IERC20(aavee).balanceOf(address(this));

        if (_wavax > 0 && _aavee > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(aavee).safeApprove(joeRouter, 0);
            IERC20(aavee).safeApprove(joeRouter, _aavee);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                aavee,
                _wavax,
                _aavee,
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
            IERC20(aavee).safeTransfer(
                IController(controller).treasury(),
                IERC20(aavee).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxAaveeLp";
    }
}
