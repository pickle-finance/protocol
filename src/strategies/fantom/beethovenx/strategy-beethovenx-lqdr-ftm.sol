// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-beethovenx-base.sol";

contract StrategyBeethovenLqdrFtmLp is StrategyBeethovenxFarmBase {
    // Token addresses
    address[] public pool_tokens = [
        0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9, // lqdr
        wftm        
    ];

    uint256 public masterchef_poolid = 36;
    bytes32 public vault_poolid = 0x5e02ab5699549675a6d3beeb92a62782712d0509000200000000000000000138;
    address public lp_token = 0x5E02aB5699549675A6d3BEEb92A62782712D0509;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBeethovenxFarmBase(
            pool_tokens, 
            vault_poolid, 
            masterchef_poolid, 
            lp_token, 
            _governance, 
            _strategist, 
            _controller, 
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyBeethovenLqdrFtmLp";
    }
}
