// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-beethovenx-base.sol";

contract StrategyBeethovenWftmUsdcLp is StrategyBeethovenxFarmBase {
    // Token addresses
    address[] public pool_tokens = [
        0x04068DA6C83AFCFA0e13ba15A6696662335D5B75, // usdc
        wftm        
    ];

    uint256 public masterchef_poolid = 8;
    bytes32 public vault_poolid = 0xcdf68a4d525ba2e90fe959c74330430a5a6b8226000200000000000000000008;
    address public lp_token = 0xcdF68a4d525Ba2E90Fe959c74330430A5a6b8226;

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
        return "StrategyBeethovenWftmUsdcLp";
    }
}
