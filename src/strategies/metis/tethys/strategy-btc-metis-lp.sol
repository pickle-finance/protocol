// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tethys-base.sol";

contract StrategyTethysBtcMetisLp is StrategyTethysFarmLPBase {
    // Token addresses
    uint256 public btc_metis_poolId = 6;
    address public btc_metis_lp = 0xA0081C6D591c53Ae651bD71B8d90C83C1F1106C2;
    address public btc = 0xa5B55ab1dAF0F8e1EFc0eB1931a957fd89B918f4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTethysFarmLPBase(
            btc_metis_lp,
            btc_metis_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[btc] = [tethys, metis, btc];
        swapRoutes[metis] = [tethys, metis];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTethysBtcMetisLp";
    }
}
