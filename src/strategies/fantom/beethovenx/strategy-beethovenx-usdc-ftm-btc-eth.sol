// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-beethovenx-base.sol";

contract StrategyBeethovenUsdcFtmBtcEthLp is StrategyBeethovenxFarmBase {
    // Token addresses
    address[] public pool_tokens = [
        0x04068DA6C83AFCFA0e13ba15A6696662335D5B75, // usdc
        wftm,
        0x321162Cd933E2Be498Cd2267a90534A804051b11, // btc
        0x74b23882a30290451A17c44f4F05243b6b58C76d  // eth
    ];

    uint256 public masterchef_poolid = 17;
    bytes32 public vault_poolid = 0xf3a602d30dcb723a74a0198313a7551feaca7dac00010000000000000000005f;
    address public lp_token = 0xf3A602d30dcB723A74a0198313a7551FEacA7DAc;

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
        return "StrategyBeethovenUsdcFtmBtcEthLp";
    }
}
