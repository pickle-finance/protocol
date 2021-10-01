// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-qi-farm-base.sol";

contract StrategyBenqiUsdt is StrategyQiFarmBase {

        address public constant usdt = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118; //qideposit token
        address public constant qiusdt = 0xc9e5999b8e75C3fEB117F6f73E664b9f3C8ca65C; //lending receipt token

        constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyQiFarmBase(
            usdt, 
            qiusdt, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyBenqiUsdt";
    }
}