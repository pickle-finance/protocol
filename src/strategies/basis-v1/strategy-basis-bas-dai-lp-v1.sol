// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-basis-farm-base-v1.sol";

contract StrategyBasisBasDaiLp is StrategyBasisFarmBaseV1 {
    // Token addresses
    address public bas_rewards = 0x9569d4CD7AC5B010DA5697E952EFB1EC0Efb0D0a;
    address public uni_bas_dai_lp = 0x0379dA7a5895D13037B6937b109fA8607a659ADF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBasisFarmBaseV1(
            bas,
            bas_rewards,
            uni_bas_dai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyBasisBasDaiLp";
    }
}
