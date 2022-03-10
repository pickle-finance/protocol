// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushiswap-base.sol";

contract StrategySushiXdaiGnoLp is StrategySushiFarmBase {
    // Token/usdo pool id in MasterChef contract
    uint256 public sushi_xdai_gno_poolid = 7;
    // Token addresses
    address public sushi_xdai_gno_lp = 0x0f9D54D9eE044220A3925f9b97509811924fD269;

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
            sushi_xdai_gno_poolid,
            sushi_xdai_gno_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraRewardBool = true;
        extraReward = gno;
        swapRoutes[gno] = [sushi, gno];
        swapRoutes[xdai] = [gno, xdai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiXdaiGnoLp";
    }
}
