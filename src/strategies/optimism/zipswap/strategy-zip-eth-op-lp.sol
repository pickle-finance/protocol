// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-zip-farm-base.sol";

contract StrategyZipEthOpLp is StrategyZipFarmBase {
    uint256 public constant weth_op_poolid = 7;
    // Token addresses
    address public constant weth_op_lp = 0x167dc49c498729223D1565dF3207771B4Ee19853;
    address public constant op = 0x4200000000000000000000000000000000000042;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyZipFarmBase(weth_op_lp, weth_op_poolid, _governance, _strategist, _controller, _timelock) {
        swapRoutes[op] = [zip, weth, op];
        swapRoutes[weth] = [zip, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyZipEthOpLp";
    }
}
