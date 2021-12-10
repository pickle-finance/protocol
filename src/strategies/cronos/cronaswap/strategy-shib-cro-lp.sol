// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaShibCroLp is StrategyCronaFarmBase {
    uint256 public shib_cro_poolId = 6;

    // Token addresses
    address public shib_cro_lp = 0x912e17882893F8361E87e81742C764B032dE8d76;
    address public shib = 0xbED48612BC69fA1CaB67052b42a95FB30C1bcFee;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            shib,
            cro,
            shib_cro_poolId,
            shib_cro_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[cro] = [crona, cro];
        uniswapRoutes[shib] = [crona, cro, shib];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaShibCroLp";
    }
}
