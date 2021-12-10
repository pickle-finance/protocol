// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaUsdtFtmLp is StrategyCronaFarmBase {
    uint256 public usdt_ftm_poolId = 10;

    // Token addresses
    address public usdt_ftm_lp = 0xDee7A79bb414FFB248EF4d4c5560AdC91F547F41;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;
    address public ftm = 0xB44a9B6905aF7c801311e8F4E76932ee959c663C;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            usdt,
            ftm,
            usdt_ftm_poolId,
            usdt_ftm_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [crona, usdt];
        uniswapRoutes[ftm] = [crona, usdt, ftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaUsdtFtmLp";
    }
}
