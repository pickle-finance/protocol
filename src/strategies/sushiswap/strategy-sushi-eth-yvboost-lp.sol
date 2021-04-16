// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthYvBoostLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_yvboost_poolId = 189;
    // Token addresses
    address public sushi_eth_yvboost_lp = 0x9461173740D27311b176476FA27e94C681b1Ea6b;
    address public yvboost = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            yvboost,
            sushi_yvboost_poolId,
            sushi_eth_yvboost_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthYvBoostLp";
    }
}
