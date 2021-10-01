// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-qi-farm-base.sol";

contract StrategyBenqiLink is StrategyQiFarmBase {
    
    address public constant link = 0x5947BB275c521040051D82396192181b413227A3; //qideposit token
    address public constant qilink = 0x4e9f683A27a6BdAD3FC2764003759277e93696e6; //lending receipt token

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyQiFarmBase(
            link, 
            qilink, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyBenqiLink";
    }
}