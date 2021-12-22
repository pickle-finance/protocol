// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-baseV2.sol";

contract StrategyMovrEthLp is StrategySolarFarmBaseV2 {
    uint256 public btc_movr_poolId = 0;

    // Token addresses
    address public btc_movr_lp = 0x32E33B774372c700da12F2D0F7A834045F5651B2;
    address public btc = 0x6aB6d61428fde76768D7b45D8BFeec19c6eF91A8;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBaseV2(
            btc,
            movr,
            btc_movr_poolId,
            btc_movr_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[btc] = [solar, usdc, btc];
        uniswapRoutes[movr] = [solar, movr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBtcMovrLp";
    }
}
