// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthMimLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_mim_poolId = 9;
    // Token addresses
    address public sushi_eth_mim_lp = 0xb6DD51D5425861C808Fd60827Ab6CFBfFE604959;
    address public mim = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            weth,
            mim,
            sushi_mim_poolId,
            sushi_eth_mim_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthMimLp";
    }
}
