// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base-v3.sol";


contract StrategyMovrXcksmLp is StrategySolarFarmBaseV3 {
    
    address public constant _lp = 0xea3d1E9e69ADDFA1ee5BBb89778Decd862F1F7C5; // WMOVR/xckcm 
    uint256 public constant _poolId = 6; 

    address public constant xcksm = 0xFfFFfFff1FcaCBd218EDc0EbA20Fc2308C778080;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategySolarFarmBaseV3(_poolId, _lp, _governance, _strategist, _controller, _timelock) {
        token0 = movr;
        token1 = xcksm;
        swapRoutes[movr] = [solar, movr]; 
        swapRoutes[xcksm] = [movr, xcksm];

    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMovrXcksmLp";
    }
}
