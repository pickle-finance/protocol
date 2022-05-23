// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-swapr-base.sol";

contract StrategySwaprCowGnoLp is StrategySwaprFarmBase {
    // Token addresses
    address public swapr_cow_gno_lp = 0xDBF14bce36F661B29F6c8318a1D8944650c73F38;
    address public rewarderContract = 0x95DBc58bCBB3Bc866EdFFC107d65D479d83799E5;
    uint256 public rewards = 3;
    address public cow = 0x177127622c4A00F3d409B75571e12cB3c8973d3c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySwaprFarmBase(
            rewarderContract,
            rewards,
            swapr_cow_gno_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        rewardRoutes[swapr] = [swapr, xdai, gno];
        rewardRoutes[cow] = [cow, gno];
        rewardRoutes[gno] = [gno];
        swapRoutes[gno] = [swapr, xdai, gno];
        swapRoutes[cow] = [gno, weth, cow];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprCowGnoLp";
    }
}
