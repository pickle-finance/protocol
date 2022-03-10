// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushiswap-base.sol";

contract StrategySushiWethXdaiLp is StrategySushiFarmBase {
    // Token/usdo pool id in MasterChef contract
    uint256 public sushi_weth_xdai_poolid = 3;
    // Token addresses
    address public sushi_weth_xdai_lp = 0x8C0C36c85192204c8d782F763fF5a30f5bA0192F;

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
            sushi_weth_xdai_poolid,
            sushi_weth_xdai_lp,
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
        swapRoutes[weth] = [sushi, gno, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiWethXdaiLp";
    }
}
