// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxLinkLp is StrategyJoeFarmBase {

    uint256 public avax_link_poolId = 5;

    address public joe_avax_link_lp = 0xA964239892FB28b5565C70A51Fd4106F29f47A52;
    address public link = 0xB3fe5374F67D7a22886A0eE082b2E2f9d2651651;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_link_poolId,
            joe_avax_link_lp,
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
            _swapTraderJoe(joe, link, _amount);
        }

        // Adds in liquidity for AVAX/LINK
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _link = IERC20(link).balanceOf(address(this));

        if (_wavax > 0 && _link > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(link).safeApprove(joeRouter, 0);
            IERC20(link).safeApprove(joeRouter, _link);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                link,
                _wavax,
                _link,
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
            IERC20(link).safeTransfer(
                IController(controller).treasury(),
                IERC20(link).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxLinkLp";
    }
}
