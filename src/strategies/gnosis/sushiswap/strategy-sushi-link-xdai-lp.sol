// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushiswap-base.sol";

contract StrategySushiLinkXdaiLp is StrategySushiFarmBase {
    // Token/usdo pool id in MasterChef contract
    uint256 public sushi_link_xdai_poolid = 4;
    // Token addresses
    address public sushi_link_xdai_lp = 0xB320609F2Bf3ca98754c14Db717307c6d6794d8b;
    address public link = 0xE2e73A1c69ecF83F464EFCE6A5be353a37cA09b2;

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
            sushi_link_xdai_poolid,
            sushi_link_xdai_lp,
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
        swapRoutes[link] = [sushi, gno, xdai, link];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiLinkXdaiLp";
    }
}
