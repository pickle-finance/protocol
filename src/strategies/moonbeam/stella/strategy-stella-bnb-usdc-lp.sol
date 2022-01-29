// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyStellaUsdcBnbLp is StrategyStellaFarmBase {
    uint256 public usdc_bnb_poolId = 4;

    // Token addresses
    address public usdc_bnb_lp = 0xAc2657ba28768FE5F09052f07A9B7ea867A4608f;
    address public usdc = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;
    address public bnb = 0xc9BAA8cfdDe8E328787E29b4B078abf2DaDc2055;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBase(
            usdc_bnb_lp,
            usdc_bnb_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [stella, usdc];
        swapRoutes[bnb] = [stella, usdc, bnb];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaUsdcBnbLp";
    }
}
