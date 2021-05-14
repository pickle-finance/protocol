// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-mushroom-farm-base.sol";

contract StrategyMushroomDai is StrategyMushroomFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public mushroom_dai_pool_id = 4;
    // Token addresses
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMushroomFarmBase(
            dai,
            mushroom_dai_pool_id,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMushroomDAIv1";
    }
}
