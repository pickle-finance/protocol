// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-basis-farm-base.sol";

contract StrategyBasisBacDaiLp is StrategyBasisFarmBase {
    // Token addresses
    address public bas_rewards = 0x067d4D3CE63450E74F880F86b5b52ea3edF9Db0f;
    address public uni_bac_dai_lp = 0xd4405F0704621DBe9d4dEA60E128E0C3b26bddbD;
    address public bac = 0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBasisFarmBase(
            bac,
            bas_rewards,
            uni_bac_dai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyBasisBacDaiLp";
    }
}
