// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadUsdcLp is StrategyNearPadFarmBase {
    uint256 public pad_usdc_poolid = 1;
    // Token addresses
    address public pad_usdc_lp = 0x73155e476D6b857fE7722AEfeBAD50F9F8bd0b38;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            pad,
            usdc,
            pad_usdc_poolid,
            pad_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [pad, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadUsdcLp";
    }
}
