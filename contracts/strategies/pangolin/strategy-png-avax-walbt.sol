// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxWalbtLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_walbt_lp_rewards = 0xa296F9474e77aE21f90afb50713F44Cc6916FbB2;
    address public png_avax_walbt_lp = 0x4555328746f1b6a9b03dE964C90eCd99d75bFFbc;
    address public walbt = 0x9E037dE681CaFA6E661e6108eD9c2bd1AA567Ecd;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            walbt,
            png_avax_walbt_lp_rewards,
            png_avax_walbt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxWalbtLp";
    }
}
