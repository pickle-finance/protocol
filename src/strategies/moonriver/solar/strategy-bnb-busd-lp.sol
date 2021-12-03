// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyBnbBusdLp is StrategySolarFarmBase {
    uint256 public bnb_busd_poolId = 11;

    // Token addresses
    address public bnb_busd_lp = 0xfb1d0D6141Fc3305C63f189E39Cc2f2F7E58f4c2;
    address public busd = 0x5D9ab5522c64E1F6ef5e3627ECCc093f56167818;
    address public bnb = 0x2bF9b864cdc97b08B6D79ad4663e71B8aB65c45c;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            bnb,
            busd,
            bnb_busd_poolId,
            bnb_busd_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[busd] = [solar, usdc, busd];
        uniswapRoutes[bnb] = [solar, movr, bnb];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBnbBusdLp";
    }
}
