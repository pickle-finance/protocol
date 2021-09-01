// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxAveLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_ave_lp_rewards = 0x94183DD08FFAa595e43B104804d55eE95492C8cB;
    address public png_avax_ave_lp = 0x62a2F206CC78BAbAC9Db4dbC0c9923D4FdDef047;
    address public ave = 0x78ea17559B3D2CF85a7F9C2C704eda119Db5E6dE;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            ave,
            png_avax_ave_lp_rewards,
            png_avax_ave_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxAveLp";
    }
}
