// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-1inch-farm-base.sol";

contract Strategy1inchEthOpiumLp is Strategy1inchFarmBase {
    
    // Token addresses
    address public oneinch_eth_opium_pool = 0x822E00A929f5A92F3565A16f92581e54af2b90Ea;
    address public oneinch_eth_opium_farm = 0x18D410f651289BB978Fc32F90D2d7E608F4f4560;
    address public opium = 0x888888888889C00c67689029D7856AAC1065eC11;    

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        Strategy1inchFarmBase(
            opium,
            oneinch_eth_opium_pool,
            oneinch_eth_opium_farm,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        baseAsset = opium;
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "Strategy1inchEthOpiumLp";
    }
}
