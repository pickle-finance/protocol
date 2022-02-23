// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettMetisMinesLp is StrategyNettFarmLPBase {
    uint256 public metis_mines_poolid = 12;
    // Token addresses
    address public metis_mines_lp = 0xA22e47e0E60CAEAaCD19A372ad3d14B9D7279e74;
    address public mines = 0xE9Aa15a067b010a4078909baDE54F0C6aBcBB852;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            metis_mines_lp,
            metis_mines_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [nett, metis];
        swapRoutes[mines] = [nett, metis, mines];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettMetisMinesLp";
    }
}
