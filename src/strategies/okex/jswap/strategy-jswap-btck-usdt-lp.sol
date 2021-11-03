// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-jswap-farm-base.sol";

contract StrategyJswapBtckUsdtLp is StrategyJswapFarmBase {
    uint256 public btck_usdt_poolId = 0;

    // Token addresses
    address public jswap_btck_usdt_lp = 0x838a7A7f3e16117763C109d98C79ddCd69F6FD6e;
    address public btck = 0x54e4622DC504176b3BB432dCCAf504569699a7fF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJswapFarmBase(
            usdt,
            btck,
            btck_usdt_poolId,
            jswap_btck_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [jswap, usdt];
        uniswapRoutes[btck] = [jswap, usdt, btck];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJswapBtckUsdtLp";
    }
}
