// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-beethovenx-base.sol";

contract StrategyBeethovenFtmBtcEthLp is StrategyBeethovenxFarmBase {
    // Token addresses
    address[] public pool_tokens = [
        wftm,
        0x321162Cd933E2Be498Cd2267a90534A804051b11, // btc
        0x74b23882a30290451A17c44f4F05243b6b58C76d  // eth
    ];

    uint256 public masterchef_poolid = 1;
    bytes32 public vault_poolid = 0xd47d2791d3b46f9452709fa41855a045304d6f9d000100000000000000000004;
    address public lp_token = 0xd47D2791d3B46f9452709Fa41855a045304D6f9d;

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
        return "StrategyBeethovenFtmBtcEthLp";
    }
}
