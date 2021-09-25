// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxUsdcELp is StrategyJoeFarmBase {

    uint256 public avax_usdce_poolId = 39;

    address public joe_avax_usdce_lp = 0xA389f9430876455C36478DeEa9769B7Ca4E3DDB1;
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_usdce_poolId,
            joe_avax_usdce_lp,
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
            _swapTraderJoe(joe, usdce, _amount);
        }

        // Adds in liquidity for AVAX/WBTC
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _usdce = IERC20(usdce).balanceOf(address(this));

        if (_wavax > 0 && _usdce > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(usdce).safeApprove(joeRouter, 0);
            IERC20(usdce).safeApprove(joeRouter, _usdce);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                usdce,
                _wavax,
                _usdce,
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
            IERC20(usdce).safeTransfer(
                IController(controller).treasury(),
                IERC20(usdce).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxUsdcELp";
    }
}
