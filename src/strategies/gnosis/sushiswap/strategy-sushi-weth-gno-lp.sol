// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushiswap-base.sol";

contract StrategySushiWethGnoLp is StrategySushiFarmBase {
    // Token/usdo pool id in MasterChef contract
    uint256 public sushi_weth_gno_poolid = 9;
    // Token addresses
    address public sushi_weth_gno_lp = 0x15f9EEdeEBD121FBb238a8A0caE38f4b4A07A585;

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
            sushi_weth_gno_poolid,
            sushi_weth_gno_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraRewardBool = true;
        extraReward = gno;
        swapRoutes[gno] = [sushi, gno];
        swapRoutes[weth] = [gno, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiWethGnoLp";
    }
}
