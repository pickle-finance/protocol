// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-swapr-base.sol";

contract StrategySwaprGnoXdaiLp is StrategySwaprFarmBase {
    // Token addresses
    address public swapr_gno_xdai_lp = 0xD7b118271B1B7d26C9e044Fc927CA31DccB22a5a;
    address public rewarderContract = 0x070386C4d038FE96ECC9D7fB722b3378Aace4863;
    uint256 public rewards = 2;

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
            swapr_gno_xdai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[gno] = [swapr, xdai, gno];
        swapRoutes[xdai] = [gno, weth, xdai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprGnoXdaiLp";
    }
}
