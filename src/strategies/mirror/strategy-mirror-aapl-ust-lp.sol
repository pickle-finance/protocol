// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-mirror-farm-base.sol";

contract StrategyMirrorAaplUstLp is StrategyMirFarmBase {
    // Token addresses
    address public aapl_rewards = 0x735659C8576d88A2Eb5C810415Ea51cB06931696;
    address public uni_aapl_ust_lp = 0xB022e08aDc8bA2dE6bA4fECb59C6D502f66e953B;
    address public mAAPL = 0xd36932143F6eBDEDD872D5Fb0651f4B72Fd15a84;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMirFarmBase(
            mAAPL,
            aapl_rewards,
            uni_aapl_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMirrorAaplUstLp";
    }
}
