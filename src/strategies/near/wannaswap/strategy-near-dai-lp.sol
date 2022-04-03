// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaNearDaiLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_near_dai_poolid = 7;
    // Token addresses
    address public wanna_near_dai_lp =
        0xE6c47B036f6Fd0684B109B484aC46094e633aF2e;
    address public dai = 0xe3520349F477A5F6EB06107066048508498A291b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            near,
            dai,
            wanna_near_dai_poolid,
            wanna_near_dai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [wanna, near];
        swapRoutes[dai] = [wanna, near, dai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaNearDaiLp";
    }
}
