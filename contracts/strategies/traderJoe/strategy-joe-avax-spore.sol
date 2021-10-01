// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxSporeLp is StrategyJoeFarmBase {

    uint256 public avax_spore_poolId = 10;

    address public joe_avax_spore_lp = 0x7012aE2B092F12Be1820acd5F1aed5d73e3116E6;
    address public spore = 0x6e7f5C0b9f4432716bDd0a77a3601291b9D9e985;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_spore_poolId,
            joe_avax_spore_lp,
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
            _takeFeeJoeToSnob(_keep);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keep));

            _swapTraderJoe(joe, wavax, _joe.sub(_keep));
        }

        // Swap half WAVAX for SPORE
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.mul(100).div(194));
            _swapTraderJoe(wavax, spore, _wavax.mul(100).div(194));
        }

        // Adds in liquidity for AVAX/SPORE
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _spore = IERC20(spore).balanceOf(address(this));
        if (_wavax > 0 && _spore > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(spore).safeApprove(joeRouter, 0);
            IERC20(spore).safeApprove(joeRouter, _spore);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                spore,
                _wavax,
                _spore,
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
            IERC20(spore).safeTransfer(
                IController(controller).treasury(),
                IERC20(spore).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxSporeLp";
    }
}
