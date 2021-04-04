// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxWbtcLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_wbtc_lp_rewards = 0x01897e996EEfFf65AE9999C02D1d8D7E9e0C0352;
    address public png_avax_wbtc_lp = 0x7a6131110B82dAcBb5872C7D352BfE071eA6A17C;
    address public wbtc = 0x408D4cD0ADb7ceBd1F1A1C33A0Ba2098E1295bAB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            wbtc,
            png_avax_wbtc_lp_rewards,
            png_avax_wbtc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxWbtcLp";
    }
}
