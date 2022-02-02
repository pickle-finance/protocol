// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-finn-farm-base.sol";

contract StrategyFinnFinnKsmLp is StrategyFinnFarmBase {
    uint256 public finn_ksm_poolId = 30;

    // Token addresses
    address public finn_ksm_lp = 0x14BE4d09c5A8237403b83A8A410bAcE16E8667DC;
    address public ksm = 0xFfFFfFff1FcaCBd218EDc0EbA20Fc2308C778080;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFinnFarmBase(
            finn,
            ksm,
            finn_ksm_poolId,
            finn_ksm_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[ksm] = [finn, ksm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFinnFinnKsmLp";
    }
}
