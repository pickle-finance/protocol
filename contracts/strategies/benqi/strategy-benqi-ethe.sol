// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-qi-farm-base.sol";

contract StrategyBenqiEth is StrategyQiFarmBase {
    
    address public constant eth = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB; //qideposit token
    address public constant qieth = 0x334AD834Cd4481BB02d09615E7c11a00579A7909; //lending receipt token

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyQiFarmBase(
            eth, 
            qieth, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyBenqiEth";
    }
}