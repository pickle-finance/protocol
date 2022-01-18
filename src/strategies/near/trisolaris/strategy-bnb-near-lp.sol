// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual.sol";

contract StrategyTriBnbNearLp is StrategyTriDualFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public bnb_near_poolid = 6;
    // Token addresses
    address public bnb_near_lp = 0x7be4a49AA41B34db70e539d4Ae43c7fBDf839DfA;
    address public bnb = 0x2bF9b864cdc97b08B6D79ad4663e71B8aB65c45c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBase(
            bnb,
            near,
            bnb_near_poolid,
            bnb_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [tri, near];
        swapRoutes[bnb] = [tri, near, bnb];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriBnbNearLp";
    }
}
