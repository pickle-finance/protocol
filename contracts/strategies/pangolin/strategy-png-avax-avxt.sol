// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxAvxtLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_avxt_lp_rewards =
        0x05930052a9a1e2f14B0e6cCc726b60E06792fB67;
    address public png_avax_avxt_lp =
        0x792055e49a6421F7544c5479eCC380bad62Bc7EE;
    address public avxt = 0x397bBd6A0E41bdF4C3F971731E180Db8Ad06eBc1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            avxt,
            png_avax_avxt_lp_rewards,
            png_avax_avxt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxAvxtLp";
    }
}
