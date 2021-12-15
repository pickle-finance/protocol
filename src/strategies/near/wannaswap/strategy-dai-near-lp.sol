// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaDaiNearLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_dai_near_poolid = 0;
    // Token addresses
    address public wanna_dai_near_lp =
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
            dai,
            near,
            wanna_dai_near_poolid,
            wanna_dai_near_lp,
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
        return "StrategyWannaDaiNearLp";
    }
}
