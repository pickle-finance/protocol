// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-liquity-farm-base.sol";

contract StrategyLusdEthLp is StrategyLiquityFarmBase {
    // Token addresses
    address public lqty_rewards = 0xd37a77E71ddF3373a79BE2eBB76B6c4808bDF0d5;
    address public uni_lusd_eth_lp = 0xF20EF17b889b437C151eB5bA15A47bFc62bfF469;
    address public lusd = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyLiquityFarmBase(
            lusd,
            lqty_rewards,
            uni_lusd_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyUniEthDaiLpV4";
    }
}
