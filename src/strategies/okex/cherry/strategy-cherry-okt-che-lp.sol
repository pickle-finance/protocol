
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cherry-farm-base.sol";

contract StrategyCherryOktCheLp is StrategyCherryFarmBase {
    uint256 public otk_che_poolId = 1;

    // Token addresses
    address public cherry_okt_che_lp = 0x8E68C0216562BCEA5523b27ec6B9B6e1cCcBbf88;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCherryFarmBase(
            cherry,
            wokt,
            otk_che_poolId,
            cherry_okt_che_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[wokt] = [cherry, wokt];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyCherryOktCheLp";
    }
}
