// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushiswap-base.sol";

contract StrategySushiUsdtUsdcLp is StrategySushiFarmBase {
    // Token/usdo pool id in MasterChef contract
    uint256 public sushi_usdt_usdc_poolid = 6;
    // Token addresses
    address public sushi_usdt_usdc_lp = 0x74c2EFA722010Ad7C142476F525A051084dA2C42;
    address public usdc = 0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83;
    address public usdt = 0x4ECaBa5870353805a9F068101A40E0f32ed605C6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            extraRewardBool,
            gno,
            sushi_usdt_usdc_poolid,
            sushi_usdt_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraRewardBool = true;
        extraReward = gno;
        swapRoutes[sushi] = [gno, sushi];
        swapRoutes[usdt] = [sushi, gno, xdai, usdt];
        swapRoutes[usdc] = [sushi, gno, xdai, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiUsdtUsdcLp";
    }
}
