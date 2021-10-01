// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-qi-farm-base.sol";

contract StrategyBenqiWbtc is StrategyQiFarmBase {
    
    address public constant wbtc = 0x50b7545627a5162F82A992c33b87aDc75187B218; //qideposit token
    address public constant qiwbtc = 0xe194c4c5aC32a3C9ffDb358d9Bfd523a0B6d1568; //lending receipt token

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyQiFarmBase(
            wbtc, 
            qiwbtc, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyBenqiWbtc";
    }
}