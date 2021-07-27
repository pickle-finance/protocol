// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxBnbLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_bnb_lp_rewards = 0x21CCa1672E95996413046077B8cf1E52F080A165;
    address public png_avax_bnb_lp = 0xF776Ef63c2E7A81d03e2c67673fd5dcf53231A3f;
    address public bnb = 0x264c1383EA520f73dd837F915ef3a732e204a493;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            bnb,
            png_avax_bnb_lp_rewards,
            png_avax_bnb_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxBnbLp";
    }
}