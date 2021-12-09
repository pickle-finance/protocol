// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadEthLp is StrategyNearPadFarmBase {
    uint256 public pad_eth_poolid = 3;
    // Token addresses
    address public pad_eth_lp = 0x63b4a0538CE8D90876B201af1020d13308a8B253;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            pad,
            eth,
            pad_eth_poolid,
            pad_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[eth] = [pad, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadEthLp";
    }
}
