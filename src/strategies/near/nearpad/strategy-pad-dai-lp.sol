// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadDaiLp is StrategyNearPadFarmBase {
    uint256 public pad_dai_poolid = 2;
    // Token addresses
    address public pad_dai_lp = 0xaf3f197Ce82bf524dAb0e9563089d443cB950048;
    address public dai = 0xe3520349F477A5F6EB06107066048508498A291b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            pad,
            dai,
            pad_dai_poolid,
            pad_dai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[dai] = [pad, dai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadDaiLp";
    }
}
