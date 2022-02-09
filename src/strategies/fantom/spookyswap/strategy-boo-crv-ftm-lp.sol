// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyCrvUsdtFtmLp is StrategyBooFarmLPBase {
    uint256 public crv_wftm_poolid = 14;
    // Token addresses
    address public crv_wftm_lp = 0xB471Ac6eF617e952b84C6a9fF5de65A9da96C93B;
    address public crv = 0x1E4F97b9f9F913c46F1632781732927B9019C68b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            crv_wftm_lp,
            crv_wftm_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[crv] = [boo, wftm, crv];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooCrvFtmLp";
    }
}
