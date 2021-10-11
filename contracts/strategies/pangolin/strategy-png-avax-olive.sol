// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxOliveLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_olive_lp_rewards =
        0x01bc14c7063212c8cAc269960bA875E58568E4fD;
    address public png_avax_olive_lp =
        0x46Ba854DC4A1F85481081b4Ab1D07b2C604B1bBE;
    address public olive = 0x617724974218A18769020A70162165A539c07E8a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            olive,
            png_avax_olive_lp_rewards,
            png_avax_olive_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxOliveLp";
    }
}
