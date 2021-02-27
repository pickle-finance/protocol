// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-1inch-farm-base.sol";

contract Strategy1inchEthOpiumLp is Strategy1inchFarmBase {
    
    // Token addresses
    address public oneinch_eth_opium_lp = 0x822E00A929f5A92F3565A16f92581e54af2b90Ea;
    address public oneinch_eth_opium_staking_pool = 0x18d410f651289bb978fc32f90d2d7e608f4f4560;
    address public opium = 0x888888888889c00c67689029d7856aac1065ec11;    

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        Strategy1inchFarmBase(
            opium,
            oneinch_eth_opium_lp,
            oneinch_eth_opium_staking_pool,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "Strategy1inchEthOpiumLp";
    }
}
