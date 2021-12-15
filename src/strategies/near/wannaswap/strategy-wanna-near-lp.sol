// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaWannaNearLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_wanna_near_poolid = 0;
    // Token addresses
    address public wanna_wanna_near_lp =
        0xbf9Eef63139b67fd0ABf22bD5504ACB0519a4212;
    address public near = 0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            wanna,
            near,
            wanna_wanna_near_poolid,
            wanna_wanna_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [wanna, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaWannaNearLp";
    }
}
