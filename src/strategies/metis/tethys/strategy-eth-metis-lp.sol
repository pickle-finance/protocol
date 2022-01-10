// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tethys-base.sol";

contract StrategyTethysEthMetisLp is StrategyTethysFarmLPBase {
    // Token addresses
    uint256 public eth_metis_poolId = 3;
    address public eth_metis_lp = 0xEE5adB5b0DfC51029Aca5Ad4Bc684Ad676b307F7;
    address public eth = 0x420000000000000000000000000000000000000A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTethysFarmLPBase(
            eth_metis_lp,
            eth_metis_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[eth] = [tethys, metis, eth];
        uniswapRoutes[metis] = [tethys, metis];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTethysEthMetisLp";
    }
}
