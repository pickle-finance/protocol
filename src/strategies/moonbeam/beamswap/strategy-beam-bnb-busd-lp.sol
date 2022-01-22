// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-beam-farm-base.sol";

contract StrategyGlintBnbBusdLp is StrategyGlintFarmBase {
    uint256 public bnb_busd_poolId = 3;

    // Token addresses
    address public bnb_busd_lp = 0x34A1F4AB3548A92C6B32cd778Eed310FcD9A340D;
    address public bnb = 0xc9BAA8cfdDe8E328787E29b4B078abf2DaDc2055;
    address public busd = 0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyGlintFarmBase(
            bnb_busd_lp,
            bnb_busd_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[busd] = [glint, glmr, busd];
        swapRoutes[bnb] = [glint, glmr, busd, bnb];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyGlintBnbBusdLp";
    }
}
