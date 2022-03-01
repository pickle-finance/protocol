// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-beethovenx-base.sol";

contract StrategyBeethovenWftmMaticSolAvaxLunaBnbLp is StrategyBeethovenxFarmBase {
    // Token addresses
    address[] public pool_tokens = [
        wftm,
        0x40DF1Ae6074C35047BFF66675488Aa2f9f6384F3, // matic
        0x44F7237df00E386af8e79B817D05ED9f6FE0f296, // sol
        0x511D35c52a3C244E7b8bd92c0C297755FbD89212, // avax
        0x95dD59343a893637BE1c3228060EE6afBf6F0730, // luna
        0xD67de0e0a0Fd7b15dC8348Bb9BE742F3c5850454 // bnb
    ];

    uint256 public masterchef_poolid = 26;
    bytes32 public vault_poolid = 0x9af1f0e9ac9c844a4a4439d446c14378071830750001000000000000000000da;
    address public lp_token = 0x9af1F0e9aC9C844A4a4439d446c1437807183075;

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
        return "StrategyBeethovenWftmMaticSolAvaxLunaBnbLp";
    }
}
