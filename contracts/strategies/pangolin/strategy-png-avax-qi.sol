// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxQiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_qi_lp_rewards = 0xeD472431e02Ea9EF8cC99B9812c335ac0873bba2;
    address public png_avax_qi_lp = 0xE530dC2095Ef5653205CF5ea79F8979a7028065c;
    address public qi = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            qi,
            png_avax_qi_lp_rewards,
            png_avax_qi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxQiLp";
    }
}
