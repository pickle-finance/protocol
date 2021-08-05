// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxYfiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_yfi_lp_rewards = 0x642c5B7AC22f56A0eF87930a89f0980FcA904B03;
    address public png_avax_yfi_lp = 0x9a634CE657681200B8c5fb3Fa1aC59Eb0662f45C;
    address public yfi = 0x9eAaC1B23d935365bD7b542Fe22cEEe2922f52dc;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            yfi,
            png_avax_yfi_lp_rewards,
            png_avax_yfi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxYfiLp";
    }
}
