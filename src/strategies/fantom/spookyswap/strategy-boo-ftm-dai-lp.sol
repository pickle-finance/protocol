// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmDaiLp is StrategyBooFarmLPBase {
    uint256 public ftm_dai_poolid = 3;
    // Token addresses
    address public ftm_dai_lp = 0xe120ffBDA0d14f3Bb6d6053E90E63c572A66a428;
    address public dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            ftm_dai_lp,
            ftm_dai_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[dai] = [boo, ftm, dai];
        swapRoutes[ftm] = [boo, ftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmDaiLp";
    }
}
