// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyMimUsdcLp is StrategySolarFarmBase {
    uint256 public mim_usdc_poolId = 19;

    // Token addresses
    address public mim_usdc_lp = 0x9051fB701d6D880800e397e5B5d46FdDfAdc7056;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;
    address public mim = 0x0caE51e1032e8461f4806e26332c030E34De3aDb;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            mim,
            usdc,
            mim_usdc_poolId,
            mim_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [solar, usdc];
        uniswapRoutes[mim] = [solar, usdc, mim];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMimUsdcLp";
    }
}
