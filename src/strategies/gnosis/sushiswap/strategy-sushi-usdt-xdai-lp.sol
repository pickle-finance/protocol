// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushiswap-base.sol";

contract StrategySushiUsdtXdaiLp is StrategySushiFarmBase {
    // Token/usdo pool id in MasterChef contract
    uint256 public sushi_xdai_usdt_poolid = 5;
    // Token addresses
    address public sushi_xdai_usdt_lp = 0x6685C047EAB042297e659bFAa7423E94b4A14b9E;
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
            sushi_xdai_usdt_poolid,
            sushi_xdai_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraRewardBool = true;
        extraReward = gno;
        swapRoutes[sushi] = [gno, sushi];
        swapRoutes[xdai] = [sushi, gno, xdai];
        swapRoutes[usdt] = [sushi, gno, xdai, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiUsdtXdaiLp";
    }
}
