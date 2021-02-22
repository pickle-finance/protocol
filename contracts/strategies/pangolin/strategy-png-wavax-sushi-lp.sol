// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

import "../wallets.sol";

contract StrategyPngAvaxSushiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_rewards = Wallets.png_rewards();
    address public png_avax_sushi_lp = Wallets.png_avax_sushi_lp();
    address public sushi = Wallets.sushi();

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            sushi,
            png_rewards,
            png_avax_sushi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxSushiLp";
    }
}
