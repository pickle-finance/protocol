// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngEthEPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_weth_png_lp_rewards = 0x03a9091620CACeE4968c915232B175C16a584733;
    address public png_weth_png_lp = 0xcf35400A595EFCF0Af591D3Aeb5a35cBCD120d54;
    address public weth = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            weth,
            png_weth_png_lp_rewards,
            png_weth_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngEthEPngLp";
    }
}
