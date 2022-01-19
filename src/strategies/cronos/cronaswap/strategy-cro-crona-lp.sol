// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaCroCronaLp is StrategyCronaFarmBase {
    uint256 public cro_crona_poolId = 1;

    // Token addresses
    address public cro_crona_lp = 0xeD75347fFBe08d5cce4858C70Df4dB4Bbe8532a0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            cro,
            crona,
            cro_crona_poolId,
            cro_crona_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[cro] = [crona, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaCroCronaLp";
    }
}
