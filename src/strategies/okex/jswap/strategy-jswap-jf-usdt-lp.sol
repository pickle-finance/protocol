// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-jswap-farm-base.sol";

contract StrategyJswapJfUsdtLp is StrategyJswapFarmBase {
    uint256 public jf_usdt_poolId = 4;

    // Token addresses
    address public jswap_jf_usdt_lp = 0x8009edebBBdeb4A3BB3003c79877fCd98ec7fB45;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJswapFarmBase(
            usdt,
            jswap,
            jf_usdt_poolId,
            jswap_jf_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJswapJfUsdtLp";
    }
}
