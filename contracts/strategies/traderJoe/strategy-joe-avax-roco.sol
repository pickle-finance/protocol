// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxRocoLp is StrategyJoeFarmBase {
    uint256 public avax_roco_poolId = 65;

    address public joe_avax_roco_lp = 0x8C28394Ed230cD6cAF0DAA0E51680fD57826DEE3;
    address public roco = 0xb2a85C5ECea99187A977aC34303b80AcbDdFa208;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_roco_poolId,
            joe_avax_roco_lp,
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
            _swapTraderJoe(joe, roco, _amount);
        }

        // Adds in liquidity for AVAX/ROCO
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _roco = IERC20(roco).balanceOf(address(this));
        if (_wavax > 0 && _roco > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(roco).safeApprove(joeRouter, 0);
            IERC20(roco).safeApprove(joeRouter, _roco);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                roco,
                _wavax,
                _roco,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _roco = IERC20(roco).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_roco > 0){
                IERC20(roco).safeTransfer(
                    IController(controller).treasury(),
                    _roco
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxRocoLp";
    }
}
