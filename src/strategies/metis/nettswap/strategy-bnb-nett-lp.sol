// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettBnbNettLp is StrategyNettSwapBase {
    uint256 public bnb_nett_poolid = 4;
    // Token addresses
    address public bnb_nett_lp = 0x3bF77b9192579826f260Bc48F2214Dfba840fcE5;
    address public bnb = 0x2692BE44A6E38B698731fDDf417d060f0d20A0cB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettSwapFarmBase(
            bnb,
            nett,
            bnb_nett_poolid,
            bnb_nett_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[bnb] = [nett, bnb];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettBnbNettLp";
    }
}
