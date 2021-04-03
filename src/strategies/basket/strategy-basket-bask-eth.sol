// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-basket-farm-base.sol";

contract StrategyBasketBaskEth is StrategyBasketFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public bask_eth_poolId = 2;
    // Token addresses
    address public sushi_bask_eth_lp = 0x34D25a4749867eF8b62A0CD1e2d7B4F7aF167E01;
    address public bask = 0x44564d0bd94343f72E3C8a0D22308B7Fa71DB0Bb;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBasketFarmBase(
            bask,
            bask_eth_poolId,
            sushi_bask_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyBasketBaskEthLp";
    }
}
