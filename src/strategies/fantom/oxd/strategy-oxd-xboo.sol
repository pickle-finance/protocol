// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-oxd-xtoken-farm-base.sol";

contract StrategyOxdXboo is StrategyOxdXtokenFarmBase {
    // Token addresses
    address public xboo = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
    address public boo = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    uint256 public xboo_poolId = 7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyOxdXtokenFarmBase(
            xboo,
            boo,
            xboo_poolId,
            "enter(uint256)",
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[boo] = [oxd, usdc, wftm, boo];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyOxdXboo";
    }
}
