// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmAvaxLp is StrategyBooFarmLPBase {
    uint256 public wftm_avax_poolid = 52;
    // Token addresses
    address public wftm_avax_lp = 0x956DE13EA0FA5b577E4097Be837BF4aC80005820;
    address public avax = 0x511D35c52a3C244E7b8bd92c0C297755FbD89212;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            wftm_avax_lp,
            wftm_avax_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[avax] = [boo, wftm, avax];
        swapRoutes[wftm] = [boo, wftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmAvaxLp";
    }
}
