// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxAvmeLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_avme_lp_rewards =
        0xE4FED988974C0B7DFEB162287DeD67c6B197Af63;
    address public png_avax_avme_lp =
        0x381CC7bCbA0afd3aEB0eaec3cb05d7796ddFd860;
    address public avme = 0x1ECd47FF4d9598f89721A2866BFEb99505a413Ed;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            avme,
            png_avax_avme_lp_rewards,
            png_avax_avme_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxAvmeLp";
    }
}
