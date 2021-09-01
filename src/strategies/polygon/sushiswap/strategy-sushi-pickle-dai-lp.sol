// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiPickleDaiLp is StrategySushiFarmBase {
    // Pickle/Dai pool id in MasterChef contract
    uint256 public sushi_pickle_dai_poolId  = 37;
    
    // Token addresses
    address public pickle_dai_slp = 0x57602582eB5e82a197baE4E8b6B80E39abFC94EB;
    address public dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public pickle = 0x2b88aD57897A8b496595925F43048301C37615Da;

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
            sushi_pickle_dai_poolId,
            pickle_dai_slp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiPickleDaiLp";
    }
}
