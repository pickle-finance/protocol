// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaCroBtcLp is StrategyCronaFarmBase {
    uint256 public cro_btc_poolId = 5;

    // Token addresses
    address public cro_btc_lp = 0xb4684F52867dC0dDe6F931fBf6eA66Ce94666860;
    address public btc = 0x062E66477Faf219F25D27dCED647BF57C3107d52;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
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
        uniswapRoutes[cro] = [crona, cro];
        uniswapRoutes[btc] = [crona, cro, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaCroBtcLp";
    }
}
