// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxRaiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_rai_lp_rewards =
        0xA69057977211C7bAe847c72dF6338d1B71E838af;
    address public png_avax_rai_lp = 0xD89DD8Dcef91bEE0a46d57681473B5Ce824D3Adf;
    address public rai = 0x97Cd1CFE2ed5712660bb6c14053C0EcB031Bff7d;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            rai,
            png_avax_rai_lp_rewards,
            png_avax_rai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxRaiLp";
    }
}
