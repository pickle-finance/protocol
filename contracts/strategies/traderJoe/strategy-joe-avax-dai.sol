// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxDaiLp is StrategyJoeFarmBase {

    uint256 public avax_dai_poolId = 3;

    address public joe_avax_dai_lp = 0x43B9C8dEC26C2D21146466cAacabf94FdbEac473;
    address public dai = 0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_dai_poolId,
            joe_avax_dai_lp,
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

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, dai, _amount);
        }

        // Adds in liquidity for AVAX/DAI
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _dai = IERC20(dai).balanceOf(address(this));

        if (_wavax > 0 && _dai > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(dai).safeApprove(joeRouter, 0);
            IERC20(dai).safeApprove(joeRouter, _dai);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                dai,
                _wavax,
                _dai,
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
            IERC20(dai).safeTransfer(
                IController(controller).treasury(),
                IERC20(dai).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxDaiLp";
    }
}
