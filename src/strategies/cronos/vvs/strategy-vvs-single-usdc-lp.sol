// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvs-farm-base.sol";

contract StrategyVvsSingleUsdcLp is StrategyVVSFarmBase {
    uint256 public vvs_single_poolId = 18;

    // Token addresses
    address public vvs_single_lp = 0x0fBAB8A90CAC61b481530AAd3a64fE17B322C25d;
    address public single = 0x0804702a4E749d39A35FDe73d1DF0B1f1D6b8347;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            vvs_single_poolId,
            vvs_single_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[single] = [vvs, single];
        uniswapRoutes[usdc] = [vvs, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyVvsSingleUsdcLp";
    }
}
