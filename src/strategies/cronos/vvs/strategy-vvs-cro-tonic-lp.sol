// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvs-farm-base.sol";

contract StrategyVvsCroTonicLp is StrategyVVSFarmBase {
    uint256 public cro_tonic_poolId = 16;

    // Token addresses
    address public cro_tonic_lp = 0x4B377121d968Bf7a62D51B96523d59506e7c2BF0;
    address public tonic = 0xDD73dEa10ABC2Bff99c60882EC5b2B81Bb1Dc5B2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            cro_tonic_poolId,
            cro_tonic_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[cro] = [vvs, cro];
        uniswapRoutes[tonic] = [vvs, tonic];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyVvsCroTonicLp";
    }
}
