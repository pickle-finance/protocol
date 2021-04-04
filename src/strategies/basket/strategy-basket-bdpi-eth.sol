// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-basket-farm-base.sol";

contract StrategyBasketBdpiEth is StrategyBasketFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public bdpi_eth_poolId = 3;
    // Token addresses
    address public sushi_bdpi_eth_lp = 0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f;
    address public bdpi = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBasketFarmBase(
            bdpi,
            bdpi_eth_poolId,
            sushi_bdpi_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyBasketBdpiEthLp";
    }
}
