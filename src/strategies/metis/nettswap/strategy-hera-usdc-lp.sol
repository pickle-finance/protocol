// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-dual-base.sol";

contract StrategyNettHeraUsdcLp is StrategyNettDualFarmLPBase {
    uint256 public constant _poolId = 17;
    // Token addresses
    address public constant _lp =
        0x948f9614628d761f86B672F134Fc273076C4D623;
    address public constant usdc = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;
    address public constant hera = 0x6F05709bc91Bad933346F9E159f0D3FdBc2c9DCE;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettDualFarmLPBase(
            _lp,
            _poolId,
            hera,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[hera] = [nett, usdc, hera];
        swapRoutes[usdc] = [hera, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettHeraUsdcLp";
    }
}
