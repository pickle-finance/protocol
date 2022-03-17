// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvs-farm-base.sol";

contract StrategyVvsCroDogeLp is StrategyVVSFarmBase {
    uint256 public cro_doge_poolId = 12;

    // Token addresses
    address public cro_doge_lp = 0x2A560f2312CB56327AD5D65a03F1bfEC10b62075;
    address public doge = 0x1a8E39ae59e5556B56b76fCBA98d22c9ae557396;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            cro_doge_poolId,
            cro_doge_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[cro] = [vvs, cro];
        uniswapRoutes[doge] = [vvs, cro, doge];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyVvsCroDogeLp";
    }
}
