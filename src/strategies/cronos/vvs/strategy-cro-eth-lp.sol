// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cronos-farm-base.sol";

contract StrategyCroEthLp is StrategyVVSFarmBase {
    uint256 public cro_eth_poolId = 1;

    // Token addresses
    address public cro_eth_lp = 0xA111C17f8B8303280d3EB01BBcd61000AA7F39F9;
    address public eth = 0xe44Fd7fCb2b1581822D0c862B68222998a0c299a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            cro,
            eth,
            cro_eth_poolId,
            cro_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[eth] = [vvs, cro, eth];
        uniswapRoutes[cro] = [vvs, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCroEthLp";
    }
}
