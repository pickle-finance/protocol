// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushiswap-base.sol";

contract StrategySushiUsdcXdaiLp is StrategySushiFarmBase {
    // Token/usdo pool id in MasterChef contract
    uint256 public sushi_xdai_usdc_poolid = 0;
    // Token addresses
    address public sushi_xdai_usdc_lp = 0xA227c72a4055A9DC949cAE24f54535fe890d3663;
    address public usdc = 0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83;

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
            sushi_xdai_usdc_poolid,
            sushi_xdai_usdc_lp,
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
        swapRoutes[usdc] = [sushi, gno, xdai, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiUsdcXdaiLp";
    }
}
