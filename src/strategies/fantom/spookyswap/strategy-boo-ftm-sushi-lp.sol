// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmSushiLp is StrategyBooFarmLPBase {
    uint256 public ftm_sushi_poolid = 10;
    // Token addresses
    address public ftm_sushi_lp = 0xf84E313B36E86315af7a06ff26C8b20e9EB443C3;
    address public sushi = 0xae75A438b2E0cB8Bb01Ec1E1e376De11D44477CC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            ftm_sushi_lp,
            ftm_sushi_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[sushi] = [boo, ftm, sushi];
        swapRotues[ftm] = [boo, ftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmSuship";
    }
}
