// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaUsdcEthLp is StrategyCronaFarmBase {
    uint256 public usdc_eth_poolId = 24;

    // Token addresses
    address public usdc_eth_lp = 0x5cc953f278bf6908B2632c65D6a202D6fd1370f9;
    address public eth = 0xe44Fd7fCb2b1581822D0c862B68222998a0c299a;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            usdc,
            eth,
            usdc_eth_poolId,
            usdc_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[eth] = [crona, usdc, eth];
        uniswapRoutes[usdc] = [crona, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaUsdcEthLp";
    }
}
