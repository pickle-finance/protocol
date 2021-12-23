// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaCroEthLp is StrategyCronaFarmBase {
    uint256 public cro_eth_poolId = 4;

    // Token addresses
    address public cro_eth_lp = 0x8232aA9C3EFf79cd845FcDa109B461849Bf1Be83;
    address public eth = 0xe44Fd7fCb2b1581822D0c862B68222998a0c299a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
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
        uniswapRoutes[cro] = [crona, cro];
        uniswapRoutes[eth] = [crona, cro, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaCroEthLp";
    }
}
