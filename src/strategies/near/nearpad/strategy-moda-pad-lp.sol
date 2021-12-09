// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyModaPadLp is StrategyNearPadFarmBase {
    uint256 public moda_pad_poolid = 16;
    // Token addresses
    address public moda_pad_lp = 0xC8F45738e2900fCaB9B72EA624F48aE2c222e248;
    address public moda = 0x74974575D2f1668C63036D51ff48dbaa68E52408;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            moda,
            pad,
            moda_pad_poolid,
            moda_pad_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[moda] = [pad, moda];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyModaPadLp";
    }
}
