// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmSpellLp is StrategyBooFarmLPBase {
    uint256 public wftm_spell_poolid = 38;
    // Token addresses
    address public wftm_spell_lp = 0x78f82c16992932EfDd18d93f889141CcF326DBc2;
    address public spell = 0x468003B688943977e6130F4F68F23aad939a1040;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            wftm_spell_lp,
            wftm_spell_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[spell] = [boo, wftm, spell];
        swapRoutes[wftm] = [boo, wftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmSpellLp";
    }
}
