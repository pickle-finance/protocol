// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cronos-farm-base.sol";

contract StrategyCroBtcLp is StrategyVVSFarmBase {
    uint256 public cro_btc_poolId = 2;

    // Token addresses
    address public cro_btc_lp = 0x8F09fFf247B8fDB80461E5Cf5E82dD1aE2EBd6d7;
    address public btc = 0x062E66477Faf219F25D27dCED647BF57C3107d52;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            cro,
            btc,
            cro_btc_poolId,
            cro_btc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[btc] = [vvs, cro, btc];
        uniswapRoutes[cro] = [vvs, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCroBtcLp";
    }
}
