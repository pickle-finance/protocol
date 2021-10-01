// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxMimLp is StrategyJoeFarmBase {

    uint256 public avax_mim_poolId = 43;

    address public joe_avax_mim_lp = 0x781655d802670bbA3c89aeBaaEa59D3182fD755D;
    address public mim = 0x130966628846BFd36ff31a822705796e8cb8C18D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_mim_poolId,
            joe_avax_mim_lp,
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
            _swapTraderJoe(joe, mim, _amount);
        }

        // Adds in liquidity for AVAX/WBTC
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _mim = IERC20(mim).balanceOf(address(this));

        if (_wavax > 0 && _mim > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(mim).safeApprove(joeRouter, 0);
            IERC20(mim).safeApprove(joeRouter, _mim);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                mim,
                _wavax,
                _mim,
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
            IERC20(mim).safeTransfer(
                IController(controller).treasury(),
                IERC20(mim).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxMimLp";
    }
}
