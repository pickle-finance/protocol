// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushiswap-base.sol";

contract StrategySushiWethWbtcLp is StrategySushiFarmBase {
    // Token/usdo pool id in MasterChef contract
    uint256 public sushi_weth_wbtc_poolid = 1;
    // Token addresses
    address public sushi_weth_wbtc_lp = 0xe21F631f47bFB2bC53ED134E83B8cff00e0EC054;
    address public wbtc = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;

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
            sushi_weth_wbtc_poolid,
            sushi_weth_wbtc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraRewardBool = true;
        extraReward = gno;
        swapRoutes[sushi] = [gno, sushi];
        swapRoutes[weth] = [sushi, gno, weth];
        swapRoutes[wbtc] = [sushi, gno, weth, wbtc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiWethWbtcLp";
    }
}
