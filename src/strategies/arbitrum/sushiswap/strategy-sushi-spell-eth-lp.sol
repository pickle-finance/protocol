// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiSpellEthLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_spell_poolId = 11;
    // Token addresses
    address public sushi_spell_eth_lp = 0x8f93Eaae544e8f5EB077A1e09C1554067d9e2CA8;
    address public spell = 0x3E6648C5a70A150A88bCE65F4aD4d506Fe15d2AF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            weth,
            spell,
            sushi_spell_poolId,
            sushi_spell_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiSpellEthLp";
    }
}
