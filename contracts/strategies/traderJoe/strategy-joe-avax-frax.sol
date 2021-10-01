// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxFraxLp is StrategyJoeFarmBase {

    uint256 public avax_frax_poolId = 46;

    address public joe_avax_frax_lp = 0x0d84595e8638dBc631076c51000B2d31120D8aa1;
    address public frax = 0xDC42728B0eA910349ed3c6e1c9Dc06b5FB591f98;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_frax_poolId,
            joe_avax_frax_lp,
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
            _swapTraderJoe(joe, frax, _amount);
        }

        // Adds in liquidity for AVAX/WBTC
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _frax = IERC20(frax).balanceOf(address(this));

        if (_wavax > 0 && _frax > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(frax).safeApprove(joeRouter, 0);
            IERC20(frax).safeApprove(joeRouter, _frax);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                frax,
                _wavax,
                _frax,
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
            IERC20(frax).safeTransfer(
                IController(controller).treasury(),
                IERC20(frax).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxFraxLp";
    }
}
