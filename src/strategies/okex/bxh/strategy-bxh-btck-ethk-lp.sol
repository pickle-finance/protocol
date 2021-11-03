
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-bxh-farm-base.sol";

contract StrategyBxhEthkBtckLp is StrategyBxhFarmBase {
    uint256 public bxh_btck_ethk_poolId = 9;

    // Token addresses
    address public bxh_btck_ethk_lp = 0x3799Fb39b7fA01E23338C1C3d652FB1AB6E7D5BC;
    address public ethk = 0xEF71CA2EE68F45B9Ad6F72fbdb33d707b872315C;
    address public btck = 0x54e4622DC504176b3BB432dCCAf504569699a7fF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBxhFarmBase(
            ethk,
            btck,
            bxh_btck_ethk_poolId,
            bxh_btck_ethk_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[ethk] = [bxh, usdt, ethk];
        uniswapRoutes[btck] = [bxh, usdt, btck];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyBxhEthkBtckLp";
    }
}
