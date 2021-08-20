// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiPickleDaiLp is StrategySushiFarmBase {
    // Pickle/Dai pool id in MasterChef contract
    uint256 public poolId = 37;
    
    // Token addresses
    address public pickle_dai_slp = 0x57602582eb5e82a197bae4e8b6b80e39abfc94eb;
    address public dai = 0x8f3cf7ad23cd3cadbd9735aff958023239c6a063;
    address public pickle = 0x2b88ad57897a8b496595925f43048301c37615da

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            pickle,
            dai,
            poolId,
            pickle_dai_slp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthUsdtLp";
    }
