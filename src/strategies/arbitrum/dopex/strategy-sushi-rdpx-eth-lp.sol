// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-dopex-farm-base.sol";

contract StrategySushiRdpxEthLp is StrategyDopexFarmBase {
    // Token addresses
    address public rdpx_eth_lp = 0x7418F5A2621E13c05d1EFBd71ec922070794b90a;
    address public reward_contract = 0x03ac1Aa1ff470cf376e6b7cD3A3389Ad6D922A74;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyDopexFarmBase(
            rdpx, // base token
            reward_contract,
            rdpx_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiRdpxEthLp";
    }
}
