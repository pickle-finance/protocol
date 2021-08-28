// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxGajLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_gaj_lp_rewards = 0xd31FFD05a41645631A22a64c1f870a6248A4DDcF;
    address public png_avax_gaj_lp = 0x278f24A782B96BE10f15df93487Aec5331CfdFF1;
    address public gaj = 0x595c8481c48894771CE8FaDE54ac6Bf59093F9E8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            gaj,
            png_avax_gaj_lp_rewards,
            png_avax_gaj_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxGajLp";
    }
}
