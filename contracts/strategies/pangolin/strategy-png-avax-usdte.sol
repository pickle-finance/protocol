// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxUsdtELp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_usdte_lp_rewards = 0x006cC053bdb84C2d6380B3C4a573d84636378A47;
    address public png_avax_usdte_lp = 0xe28984e1EE8D431346D32BeC9Ec800Efb643eef4;
    address public usdte = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            usdte,
            png_avax_usdte_lp_rewards,
            png_avax_usdte_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxUsdtELp";
    }
}
