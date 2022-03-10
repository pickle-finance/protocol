// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushiswap-base.sol";

contract StrategySushiSushiGnoLp is StrategySushiFarmBase {
    // Token/usdo pool id in MasterChef contract
    uint256 public sushi_sushi_gno_poolid = 10;
    // Token addresses
    address public sushi_sushi_gno_lp = 0xF38c5b39F29600765849cA38712F302b1522C9B8;

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
            sushi_sushi_gno_poolid,
            sushi_sushi_gno_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraRewardBool = true;
        extraReward = gno;
        swapRoutes[gno] = [sushi, gno];
        swapRoutes[sushi] = [gno, sushi];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiSushiGnoLp";
    }
}
