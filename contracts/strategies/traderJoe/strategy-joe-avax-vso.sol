// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxVsoLp is StrategyJoeFarmBase {

    uint256 public avax_vso_poolId = 11;

    address public joe_avax_vso_lp = 0x00979Bd14bD5Eb5c456c5478d3BF4b6E9212bA7d;
    address public vso = 0x846D50248BAf8b7ceAA9d9B53BFd12d7D7FBB25a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_vso_poolId,
            joe_avax_vso_lp,
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
        // if so, a new strategy will be deployed.

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
            _swapTraderJoe(joe, vso, _amount);
        }

        // Collects VSO tokens for double reward
        uint256 _vso = IERC20(vso).balanceOf(address(this));
        if (_vso > 0) {
            // 10% is sent to treasury
            uint256 _keepVSO = _vso.mul(keep).div(keepMax);
            IERC20(vso).safeTransfer(
                IController(controller).treasury(),
                _keepVSO
            );
            uint256 _amount = _vso.sub(_keepVSO).div(2);
            IERC20(vso).safeApprove(joeRouter, 0);
            IERC20(vso).safeApprove(joeRouter, _vso.sub(_keepVSO));

            _swapTraderJoe(vso, wavax, _amount);
        }

        // Adds in liquidity for AVAX/VSO
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        _vso = IERC20(vso).balanceOf(address(this));

        if (_wavax > 0 && _vso > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(vso).safeApprove(joeRouter, 0);
            IERC20(vso).safeApprove(joeRouter, _vso);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                vso,
                _wavax,
                _vso,
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
            IERC20(vso).safeTransfer(
                IController(controller).treasury(),
                IERC20(vso).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxVsoLp";
    }
}
