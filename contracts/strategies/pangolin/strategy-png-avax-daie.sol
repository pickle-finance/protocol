// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxDaiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_dai_lp_rewards = 0x63A84F66b8c90841Cb930F2dC3D28799F0c6657B;
    address public png_avax_dai_lp = 0xbA09679Ab223C6bdaf44D45Ba2d7279959289AB0;
    address public dai = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            dai,
            png_avax_dai_lp_rewards,
            png_avax_dai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxDaiLp";
    }
}
