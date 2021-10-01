// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-qi-farm-base.sol";

contract StrategyBenqiDai is StrategyQiFarmBase {
    
        address public constant dai = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70; //qideposit token	
        address public constant qidai = 0x835866d37AFB8CB8F8334dCCdaf66cf01832Ff5D; //lending receipt token	
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyQiFarmBase(
            dai, 
            qidai, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyBenqiDai";
    }
}