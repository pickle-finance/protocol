// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaBtcCroLp is StrategyCronaFarmBase {
    uint256 public btc_cro_poolId = 5;

    // Token addresses
    address public btc_cro_lp = 0x8232aA9C3EFf79cd845FcDa109B461849Bf1Be83;
    address public btc = 0x062E66477Faf219F25D27dCED647BF57C3107d52;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            btc,
            cro,
            btc_cro_poolId,
            btc_cro_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[cro] = [crona, cro];
        uniswapRoutes[btc] = [crona, cro, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaBtcCroLp";
    }
}
