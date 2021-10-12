// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxSpellLp is StrategyJoeFarmBase {
    uint256 public avax_spell_poolId = 48;

    address public joe_avax_spell_lp =
        0x62cf16BF2BC053E7102E2AC1DEE5029b94008d99;
    address public spell = 0xCE1bFFBD5374Dac86a2893119683F4911a2F7814;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_spell_poolId,
            joe_avax_spell_lp,
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
            _swapTraderJoe(joe, spell, _amount);
        }

        // Adds in liquidity for AVAX/spell
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _spell = IERC20(spell).balanceOf(address(this));

        if (_wavax > 0 && _spell > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(spell).safeApprove(joeRouter, 0);
            IERC20(spell).safeApprove(joeRouter, _spell);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                spell,
                _wavax,
                _spell,
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
            IERC20(spell).safeTransfer(
                IController(controller).treasury(),
                IERC20(spell).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxSpellLp";
    }
}
