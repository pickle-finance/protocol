// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlBrlEthLp is StrategyBrlFarmBase {
    uint256 public brl_eth_poolid = 14;
    // Token addresses
    address public brl_eth_lp = 0xEfCF518CA36DC3362F539965807b42A77DC26Be0;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            brl,
            eth,
            brl_eth_poolid,
            brl_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[eth] = [brl, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlBrlEthLp";
    }
}
