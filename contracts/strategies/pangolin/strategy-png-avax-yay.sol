// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxYayLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_yay_lp_rewards = 0x2DaE4d6Cccd824917cA783774C1e8854FF86951F;
    address public png_avax_yay_lp = 0x04D80d453033450703E3DC2d0C1e0C0281c42D81;
    address public yay = 0x01C2086faCFD7aA38f69A6Bd8C91BEF3BB5adFCa;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            yay,
            png_avax_yay_lp_rewards,
            png_avax_yay_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxYayLp";
    }
}
