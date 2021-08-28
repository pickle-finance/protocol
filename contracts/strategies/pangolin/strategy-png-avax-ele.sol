// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxEleLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_ele_lp_rewards = 0x10E5d5f598abb970F85456Ea59f0611D77E00168;
    address public png_avax_ele_lp = 0x9e14eBC3c312d1CADa4E16001FD53b222902E103;
    address public ele = 0xAcD7B3D9c10e97d0efA418903C0c7669E702E4C0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            ele,
            png_avax_ele_lp_rewards,
            png_avax_ele_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxEleLp";
    }
}
