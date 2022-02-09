// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooYfiEthLp is StrategyBooFarmLPBase {
    uint256 public yfi_eth_poolid = 26;
    // Token addresses
    address public yfi_eth_lp = 0x0845c0bFe75691B1e21b24351aAc581a7FB6b7Df;
    address public eth = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
    address public yfi = 0x29b0Da86e484E1C0029B56e817912d778aC0EC69;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            yfi_eth_lp,
            yfi_eth_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[yfi] = [boo, ftm, eth, yfi];
        swapRoutes[eth] = [boo, ftm, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooYfiEthLp";
    }
}
